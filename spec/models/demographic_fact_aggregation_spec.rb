require 'spec_helper'
require 'csv'

describe DemographicFact, :type => :model do

  describe "aggregation" do

    before(:each) do
      AreasCreator.create_areas
      @view = FactoryGirl.create(:view2)
      s1 = FactoryGirl.create(:statistic)
      s2 = FactoryGirl.create(:statistic2)
      [
        # area, year, statistic, value
        # in nassau, so in subregion: 'long_island', region: 'nybpm_counties', 'nymtc_planning_area'
        ['taz1623', 2015, s1, 1],
        ['taz1623', 2015, s1, 3],
        ['taz1623', 2020, s1, 5],
        ['taz1623', 2020, s1, 7],

        ['taz1624', 2015, s1, 11],
        ['taz1624', 2015, s1, 13],
        ['taz1624', 2020, s1, 15],
        ['taz1624', 2020, s1, 17],

        # in bergen, so in subregion: 'new_jersey', region: 'nybpm_counties'
        ['taz2661', 2015, s1, 21],
        ['taz2661', 2015, s1, 23],
        ['taz2661', 2020, s1, 25],
        ['taz2661', 2020, s1, 27],

        ['taz2662', 2015, s1, 31],
        ['taz2662', 2015, s1, 33],
        ['taz2662', 2020, s1, 35],
        ['taz2662', 2020, s1, 37],

        ['Bergen', 2015, s1, 27],
        ['Bergen', 2020, s1, 31],
        
        # in essex, so in subregion: 'new_jersey', region: 'nybpm_counties'
        ['taz2906', 2015, s1, 41],
        ['taz2906', 2015, s1, 43],
        ['taz2906', 2020, s1, 45],
        ['taz2906', 2020, s1, 47],

        ['taz2907', 2015, s1, 51],
        ['taz2907', 2015, s1, 53],
        ['taz2907', 2020, s1, 55],
        ['taz2907', 2020, s1, 57],

        ['Essex', 2015, s1, 47],
        ['Essex', 2020, s1, 51],

        # in essex, but different statistic
        ['taz2906', 2015, s2, 100],

      ].each do |v|
        FactoryGirl.create(:demographic_fact,
          view: @view,
          area: Area.where(name: v[0]).first,
          year: v[1],
          statistic: v[2],
          value: v[3]
          )
      end

      # DemographicFact.all.each do |d|
      #   puts [d.area.name, d.area.type, d.year, d.statistic_id, d.value].join("\t")
      # end

    end

    describe "metadata" do
      it "should throw an exception if no data_hierarchy defined" do
        view = View.new spatial_level: Area::AREA_LEVELS[:taz], data_hierarchy: []
        expect { DemographicFact.aggregate(view, Area::AREA_LEVELS[:county]) }.to raise_error
        view = View.new spatial_level: Area::AREA_LEVELS[:taz]
        expect { DemographicFact.aggregate(view, Area::AREA_LEVELS[:county]) }.to raise_error
      end

      it "should throw an exception if not aggregatable to desired level" do
        view = View.new spatial_level: Area::AREA_LEVELS[:taz], data_hierarchy: [['taz', 'subregion', 'region']]
        expect { DemographicFact.aggregate(view, Area::AREA_LEVELS[:county]) }.to raise_error
      end

      it "should not throw an exception if aggregatable to desired level" do
        view = View.new spatial_level: Area::AREA_LEVELS[:taz],
          data_hierarchy: [
            ['taz', ['subregion', 'region']],
            ['taz', 'county', ['subregion', 'region']]
          ]
        DemographicFact.aggregate(view, Area::AREA_LEVELS[:county])
      end
    end

    describe "generated sql" do
      # These 3 examples should probably go away, since it's possible the SQL could change. But it'd be good to know if
      # it does.

      it "should produce right SQL for 1-level aggregation" do |example|
        query = <<-QUERY
SELECT "demographic_facts".* FROM "demographic_facts" INNER JOIN "areas" ON "areas"."id" = "demographic_facts"."area_id" INNER JOIN "area_enclosures" ON "area_enclosures"."enclosed_area_id" = "areas"."id" INNER JOIN "areas" "enclosing_areas_areas" ON "enclosing_areas_areas"."id" = "area_enclosures"."enclosing_area_id" WHERE "demographic_facts"."view_id" = %{view_id} AND (enclosing_areas_areas.type = 'county') GROUP BY demographic_facts.year, enclosing_areas_areas.name
        QUERY
        view = FactoryGirl.create(:view2)
        s = DemographicFact.aggregate_query(view, Area::AREA_LEVELS[:county]).to_sql
        query = (query % {view_id: view.id}).chomp
        expect(s.chomp).to eq(query)
      end

      it "should produce right SQL for 2nd-level aggregation" do |example|
        query = <<-QUERY
SELECT "demographic_facts".* FROM "demographic_facts" INNER JOIN "areas" ON "areas"."id" = "demographic_facts"."area_id" INNER JOIN "area_enclosures" ON "area_enclosures"."enclosed_area_id" = "areas"."id" INNER JOIN "areas" "enclosing_areas_areas" ON "enclosing_areas_areas"."id" = "area_enclosures"."enclosing_area_id" INNER JOIN "area_enclosures" "areas_enclosings_areas_join" ON "areas_enclosings_areas_join"."enclosed_area_id" = "enclosing_areas_areas"."id" INNER JOIN "areas" "enclosing_areas_areas_2" ON "enclosing_areas_areas_2"."id" = "areas_enclosings_areas_join"."enclosing_area_id" WHERE "demographic_facts"."view_id" = %{view_id} AND (enclosing_areas_areas_2.type = 'subregion') GROUP BY demographic_facts.year, enclosing_areas_areas_2.name
        QUERY
        view = FactoryGirl.create(:view2)
        s = DemographicFact.aggregate_query(view, Area::AREA_LEVELS[:subregion]).to_sql
        query = (query % {view_id: view.id}).chomp
        expect(s.chomp).to eq(query)
      end

      it "should produce right SQL for 2nd-level aggregation with a filter" do |example|
        query = <<-QUERY
SELECT "demographic_facts".* FROM "demographic_facts" INNER JOIN "areas" ON "areas"."id" = "demographic_facts"."area_id" INNER JOIN "area_enclosures" ON "area_enclosures"."enclosed_area_id" = "areas"."id" INNER JOIN "areas" "enclosing_areas_areas" ON "enclosing_areas_areas"."id" = "area_enclosures"."enclosing_area_id" INNER JOIN "area_enclosures" "areas_enclosings_areas_join" ON "areas_enclosings_areas_join"."enclosed_area_id" = "enclosing_areas_areas"."id" INNER JOIN "areas" "enclosing_areas_areas_2" ON "enclosing_areas_areas_2"."id" = "areas_enclosings_areas_join"."enclosing_area_id" WHERE "demographic_facts"."view_id" = %{view_id} AND (enclosing_areas_areas_2.type = 'subregion') AND (enclosing_areas_areas.id = %{area_id}) GROUP BY demographic_facts.year, enclosing_areas_areas_2.name
        QUERY
        view = FactoryGirl.create(:view2)
        area = FactoryGirl.create(:area)
        s = DemographicFact.aggregate_query(view, Area::AREA_LEVELS[:subregion], area).to_sql
        query = (query % {view_id: view.id, area_id: area.id}).chomp
        expect(s.chomp).to eq(query)
      end

#       it "should produce right SQL for 3rd-level aggregation" do |example|
#         query = <<-QUERY
# SELECT "demographic_facts".* FROM "demographic_facts" INNER JOIN "areas" ON "areas"."id" = "demographic_facts"."area_id" INNER JOIN "area_enclosures" ON "area_enclosures"."enclosed_area_id" = "areas"."id" INNER JOIN "areas" "enclosing_areas_areas" ON "enclosing_areas_areas"."id" = "area_enclosures"."enclosing_area_id" INNER JOIN "area_enclosures" "areas_enclosings_areas_join" ON "areas_enclosings_areas_join"."enclosed_area_id" = "enclosing_areas_areas"."id" INNER JOIN "areas" "enclosing_areas_areas_2" ON "enclosing_areas_areas_2"."id" = "areas_enclosings_areas_join"."enclosing_area_id" INNER JOIN "area_enclosures" "areas_enclosings_areas_join_2" ON "areas_enclosings_areas_join_2"."enclosed_area_id" = "enclosing_areas_areas_2"."id" INNER JOIN "areas" "enclosing_areas_areas_3" ON "enclosing_areas_areas_3"."id" = "areas_enclosings_areas_join_2"."enclosing_area_id" WHERE "demographic_facts"."view_id" = %{view_id} GROUP BY year, enclosing_areas_areas_3.name
#   QUERY
#         view = FactoryGirl.create(:view3)
#         s = DemographicFact.aggregate_query(view, Area::AREA_LEVELS[:region]).to_sql
#         query = (query % {view_id: view.id}).chomp
#         expect(s.chomp).to eq(query.chomp)
#       end
    end

    describe "disallowed aggregations" do
    end

    describe "actual aggregation" do

      describe "aggregate to county" do
        it "filtering at subregion" do
          # filter at subregion
          filter_new_jersey = Area.where(name: 'new_jersey').first

          agg = DemographicFact.aggregate(@view, Area::AREA_LEVELS[:county], filter_new_jersey)
          expect(agg).not_to be_nil
          expect(agg).to eq({[2020, "Bergen"]=>124.0, [2015, "Essex"]=>288.0, [2015, "Bergen"]=>108.0, [2020, "Essex"]=>204.0})
        end

        it "filtering at region" do
          filter_new_jersey = Area.where(name: 'nymtc_planning_area').first

          agg = DemographicFact.aggregate(@view, Area::AREA_LEVELS[:county], filter_new_jersey)
          expect(agg).not_to be_nil
          expect(agg).to eq({[2020, "Nassau"]=>44.0, [2015, "Nassau"]=>28.0})
        end

        it "filtering at county" do
          @view.spatial_level = 'county'
          @view.data_hierarchy = [
            ['county', ['subregion', 'region']]
          ]
          filter_new_jersey = Area.where(name: 'new_jersey').first

          agg = DemographicFact.aggregate(@view, Area::AREA_LEVELS[:county], filter_new_jersey)
          expect(agg).not_to be_nil
          expect(agg).to eq({[2020, "Bergen"]=>31.0, [2015, "Bergen"]=>27.0, [2020, "Essex"]=>51.0, [2015, "Essex"]=>47.0})
        end
      end

    end

  # data_levels = {
  #   level: ['taz'],
  #   hierarchies: [
  #     ['taz', 'county', 'region'],
  #     ['taz', 'county', 'subregion']
  #   ]
  # }

  # data_levels = {
  #   level: ['taz'],
  #   hierarchies: [
  #     {'taz' =>
  #       {
  #         'county' => [
  #           'region',
  #           'subregion'
  #         ]
  #       }
  #     }
  #   ]
  # }


  # DemographicFact.joins(area: {areas_enclosing: :enclosing_area})
  #   .where(view: view)
  #   .group(:year, 'enclosing_areas_area_enclosures.name', 'enclosing_areas_area_enclosures.type')
  #   .sum(:value)

  # DemographicFact.joins(area: {areas_enclosing: :enclosing_area}).where(view: view).group(:year, 'enclosing_areas_area_enclosures.name', 'enclosing_areas_area_enclosures.type').sum(:value)

  # DemographicFact.joins(area: {areas_enclosing: {enclosing_area: {areas_enclosing: :enclosing_area}}})
  #   .where(view: view)
  #   .where('enclosing_areas_area_enclosures_2.type = ?', 'region')
  #   .group(:year, 'enclosing_areas_area_enclosures_2.name', 'enclosing_areas_area_enclosures_2.type')
  #   .sum(:value)

  end

end
