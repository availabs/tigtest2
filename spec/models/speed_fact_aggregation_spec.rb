require 'spec_helper'
require 'gateway_monkey_patch_postgres.rb'
require 'gateway_reader.rb'

describe SpeedFact, type: :model do

  before(:all) do
    SpeedFact.create_infrastructure
    SpeedFact.create_new_partition_tables([2013, [2013, 9]])
  end

  after(:all) do
    SpeedFact.delete_infrastructure
  end
  
  describe "aggregation" do

    before(:each) do
      AreasCreator.create_areas
      @view = FactoryGirl.create(:view2)
      s1 = FactoryGirl.create(:statistic)
      ['120N04917', '120N04918', '120N04291', '120N04292', '120N04309', '120N04343'].each do |t|
        FactoryGirl.create(:tmc, name: t)
      end
      [
        # tmc, county, hour, value
        # in nassau, subregion: 'long_island', region: 'nybpm_counties', 'nymtc_planning_area'
        ['120N04917', 'Nassau', 1, 65],
        ['120N04917', 'Nassau', 2, 64],
        ['120N04918', 'Nassau', 1, 63],
        ['120N04918', 'Nassau', 2, 63],

        # in bergen, so in subregion: 'new_jersey', region: 'nybpm_counties'
        ['120N04291', 'Bergen', 1, 53],
        ['120N04291', 'Bergen', 2, 55],
        ['120N04292', 'Bergen', 1, 59],
        ['120N04292', 'Bergen', 2, 50],

        # in essex, so in subregion: 'new_jersey', region: 'nybpm_counties'
        ['120N04309', 'Essex', 1, 63],
        ['120N04309', 'Essex', 2, 64],
        ['120N04343', 'Essex', 1, 43],
        ['120N04343', 'Essex', 2, 10],
      ].each do |f|
        FactoryGirl.create(
          :speed_fact,
          tmc: Tmc.where(name: f[0]).first,
          view: @view,
          year: 2013,
          month: 9,
          day_of_week: 5,
          area: Area.where(name: f[1]).first,
          hour: f[2],
          speed: f[3]
        )
      end

      # puts
      # SpeedFact.all.each do |s|
      #   puts [s.area.name, s.hour, s.speed, s.vehicle_class].join("\t")
      # end
      
      @filters = {year: 2013, month: 9, day_of_week: 5, vehicle_class: 1}
    end

    describe "metadata" do
      it "should throw an exception if no data_hierarchy defined" do
        view = View.new spatial_level: Area::AREA_LEVELS[:taz], data_hierarchy: []
        expect { SpeedFact.aggregate(view, Area::AREA_LEVELS[:county], nil, nil, nil, @filters) }.to raise_error
        view = View.new spatial_level: Area::AREA_LEVELS[:taz]
        expect { SpeedFact.aggregate(view, Area::AREA_LEVELS[:county], nil, nil, nil, @filters) }.to raise_error
      end

      it "should throw an exception if not aggregatable to desired level" do
        view = View.new spatial_level: Area::AREA_LEVELS[:taz], data_hierarchy: [['taz', 'subregion', 'region']]
        expect { SpeedFact.aggregate(view, Area::AREA_LEVELS[:county], nil, nil, nil, @filters) }.to raise_error
      end

      it "should not throw an exception if aggregatable to desired level" do
        view = View.new spatial_level: Area::AREA_LEVELS[:taz],
          data_hierarchy: [
            ['taz', ['subregion', 'region']],
            ['taz', 'county', ['subregion', 'region']]
          ]
        SpeedFact.aggregate(view, Area::AREA_LEVELS[:county], nil, nil, nil, @filters)
      end
    end

    describe "generated sql" do
      # The SQL could change if the underlying implementation changes, e.g with version upgrade,
      # but it would still be useful to know if that happens.
      it "should produce right SQL for 1st-level aggregation" do |example|
        query = <<-QUERY
SELECT \"speed_facts\".\"id\" AS t0_r0, \"speed_facts\".\"tmc_id\" AS t0_r1, \"speed_facts\".\"year\" AS t0_r2, \"speed_facts\".\"month\" AS t0_r3, \"speed_facts\".\"day_of_week\" AS t0_r4, \"speed_facts\".\"hour\" AS t0_r5, \"speed_facts\".\"road_id\" AS t0_r6, \"speed_facts\".\"vehicle_class\" AS t0_r7, \"speed_facts\".\"direction\" AS t0_r8, \"speed_facts\".\"area_id\" AS t0_r9, \"speed_facts\".\"speed\" AS t0_r10, \"speed_facts\".\"created_at\" AS t0_r11, \"speed_facts\".\"updated_at\" AS t0_r12, \"speed_facts\".\"view_id\" AS t0_r13, \"speed_facts\".\"base_geometry_id\" AS t0_r14, \"areas\".\"id\" AS t1_r0, \"areas\".\"name\" AS t1_r1, \"areas\".\"type\" AS t1_r2, \"areas\".\"created_at\" AS t1_r3, \"areas\".\"updated_at\" AS t1_r4, \"areas\".\"size\" AS t1_r5, \"areas\".\"base_geometry_id\" AS t1_r6, \"areas\".\"fips_code\" AS t1_r7, \"areas\".\"year\" AS t1_r8, \"areas\".\"user_id\" AS t1_r9, \"areas\".\"description\" AS t1_r10, \"areas\".\"published\" AS t1_r11 FROM \"speed_facts_partitions\".\"p2013_9\" \"speed_facts\" INNER JOIN \"areas\" ON \"areas\".\"id\" = \"speed_facts\".\"area_id\" WHERE \"speed_facts\".\"view_id\" = %{view_id} AND \"speed_facts\".\"year\" = 2013 AND \"speed_facts\".\"month\" = 9 AND \"speed_facts\".\"day_of_week\" = 5 AND \"speed_facts\".\"vehicle_class\" = 1 AND (areas.type = 'county') GROUP BY hour, areas.name
       QUERY
        view = FactoryGirl.create(:view2)
        s = SpeedFact.aggregate_query(view, Area::AREA_LEVELS[:county], @filters).to_sql
        query = (query % {view_id: view.id}).chomp
        expect(s.chomp).to eq(query)
      end
      it "should produce right SQL for 2nd-level aggregation" do |example|
        query = <<-QUERY
SELECT \"speed_facts\".* FROM \"speed_facts_partitions\".\"p2013_9\" \"speed_facts\" INNER JOIN \"areas\" ON \"areas\".\"id\" = \"speed_facts\".\"area_id\" INNER JOIN \"area_enclosures\" ON \"area_enclosures\".\"enclosed_area_id\" = \"areas\".\"id\" INNER JOIN \"areas\" \"enclosing_areas_areas\" ON \"enclosing_areas_areas\".\"id\" = \"area_enclosures\".\"enclosing_area_id\" WHERE \"speed_facts\".\"view_id\" = %{view_id} AND \"speed_facts\".\"year\" = 2013 AND \"speed_facts\".\"month\" = 9 AND \"speed_facts\".\"day_of_week\" = 5 AND \"speed_facts\".\"vehicle_class\" = 1 AND (enclosing_areas_areas.type = 'subregion') GROUP BY hour, enclosing_areas_areas.name
        QUERY
        view = FactoryGirl.create(:view2)
        s = SpeedFact.aggregate_query(view, Area::AREA_LEVELS[:subregion], @filters).to_sql
        query = (query % {view_id: view.id}).chomp
        expect(s.chomp).to eq(query)
      end
      it "should produce right SQL for 2nd-level aggregation with a filter" do |example|
        query = <<-QUERY
SELECT \"speed_facts\".* FROM \"speed_facts_partitions\".\"p2013_9\" \"speed_facts\" INNER JOIN \"areas\" ON \"areas\".\"id\" = \"speed_facts\".\"area_id\" INNER JOIN \"area_enclosures\" ON \"area_enclosures\".\"enclosed_area_id\" = \"areas\".\"id\" INNER JOIN \"areas\" \"enclosing_areas_areas\" ON \"enclosing_areas_areas\".\"id\" = \"area_enclosures\".\"enclosing_area_id\" WHERE \"speed_facts\".\"view_id\" = %{view_id} AND \"speed_facts\".\"year\" = 2013 AND \"speed_facts\".\"month\" = 9 AND \"speed_facts\".\"day_of_week\" = 5 AND \"speed_facts\".\"vehicle_class\" = 1 AND \"speed_facts\".\"area_id\" IN (%{area_id}) AND (enclosing_areas_areas.type = 'subregion') AND (enclosing_areas_areas.id = %{area_id}) GROUP BY hour, enclosing_areas_areas.name
        QUERY
        view = FactoryGirl.create(:view2)
        area = FactoryGirl.create(:area)
        s = SpeedFact.aggregate_query(view, Area::AREA_LEVELS[:subregion], @filters, area).to_sql
        query = (query % {view_id: view.id, area_id: area.id}).chomp
        expect(s.chomp).to eq(query)
      end
    end

    describe "actual aggregation" do

      describe "aggregate to county" do
        it "no filtering" do
          agg = SpeedFact.aggregate(@view, Area::AREA_LEVELS[:county], nil, nil, nil, @filters)
          expect(agg).not_to be_nil
          expect(agg).to include({[1, "Nassau"]=>64.0,
                                  [2, "Nassau"]=>63.5,
                                  [1, "Bergen"]=>56.0,
                                  [1, "Essex"]=>53.0,
                                  [2, "Bergen"]=>52.5,
                                  [2, "Essex"]=>37.0})
        end
        it "filtering at subregion" do
          filter_subregion = Area.where(name: 'new_jersey').first

          agg = SpeedFact.aggregate(@view, Area::AREA_LEVELS[:county], filter_subregion, nil, nil, @filters)
          expect(agg).not_to be_nil
          expect(agg).to include({[1, "Bergen"]=>56.0, [1, "Essex"]=>53.0, [2, "Bergen"]=>52.5, [2, "Essex"]=>37.0})
        end

        it "filtering at region" do
          filter_region = Area.where(name: 'nymtc_planning_area').first

          agg = SpeedFact.aggregate(@view, Area::AREA_LEVELS[:county], filter_region, nil, nil, @filters)
          expect(agg).not_to be_nil
          expect(agg).to include({[1, "Nassau"]=>64.0, [2, "Nassau"]=>63.5})
        end
      end

    end

  end

end

        
