require 'spec_helper'
require 'csv'

describe DemographicFact, :type => :model do

  def setup_simple
    @area = Area.find_or_create_by( name: "area" )
    @area.update_attributes(size: 1.0)
    @area2 = Area.find_or_create_by( name: "area2" )
    @area2.update_attributes(size: 2.0)
    
    stat = Statistic.find_or_create_by( name: "Pop" )
    @view.update_attributes(columns: ['area', '2020', '2025'])

    @fact = DemographicFact.where(view_id: @view, 
                                 year: 2020, 
                                 area_id: @area, 
                                 statistic_id: stat).first_or_create
    @fact.update_attributes(value: 1)
    fact = DemographicFact.where(view_id: @view, 
                                 year: 2025, 
                                 area_id: @area,
                                 statistic_id: stat).first_or_create
    fact.update_attributes(value: 2)
    fact = DemographicFact.where(view_id: @view, 
                                 year: 2025, 
                                 area_id: @area2, 
                                 statistic_id: stat).first_or_create
    fact.update_attributes(value: 4)
  end
  
  before(:each) do
    @view = View.find_or_create_by( name: "view", data_model: CountFact )
  end
  
  it "should provide a grid for a view" do
    setup_simple

    grid = DemographicFact.grid(@view, nil)

    expect(grid.rows.count).to eq(2)
    expect(grid.columns.count).to eq(2)
    expect(grid.columns.first.header.name).to eq('area')
  end

  it "should provide a grid for a view and an enclosing area" do
    setup_simple

    area1 = Area.find_or_create_by( name: "area1" )
    @area.enclosing_areas << area1
    @area.save!
    
    grid = DemographicFact.grid(@view, area1)

    expect(grid.rows.count).to eq(2)
    expect(grid.columns.count).to eq(1)
    expect(grid.columns.first.header.name).to eq('area')

    area3 = Area.find_or_create_by( name: "area3" )

    grid = DemographicFact.grid(@view, area3)

    expect(grid.rows.count).to eq(0)
    
  end

  it "should provide a grid for a view and area with density" do
    setup_simple
    @view.update_attributes(value_name: :density)
    @area.update_attributes(size: 2.0)
    
    area1 = Area.find_or_create_by( name: "area1" )
    @area.enclosing_areas << area1
    @area.save!
    
    grid = DemographicFact.grid(@view, area1)
    
    expect(grid.rows.count).to eq(2)
    expect(grid.columns.count).to eq(1)
    expect(grid.columns.first.header.name).to eq('area')

    expect(grid.rows[0].data[0].density).to eq(0.5)
    expect(grid.rows[1].data[0].density).to eq(1.0)
    
    area3 = Area.find_or_create_by( name: "area3" )

    grid = DemographicFact.grid(@view, area3)

    expect(grid.rows.count).to eq(0)
    
  end

  it "should provide a max value for a view and an enclosing area" do
    setup_simple

    max = DemographicFact.max_value(@view, nil)

    expect(max).to eq(4)

    area1 = Area.find_or_create_by( name: "area1" )
    @area.enclosing_areas << area1
    @area.save!

    max = DemographicFact.max_value(@view, area1)

    expect(max).to eq(2)
  end
  
  it "should be pivotable" do
    expect(DemographicFact.pivot?).to eql(true)
  end

  it "should produce a pivot table" do
    setup_simple

    rows = DemographicFact.pivot(@view)

    expect(rows.count).to eq(2)
    expect(rows[0]['area']).to eq('area')
    expect(rows[0]['2020']).to eq(1)
    expect(rows[0]['2025']).to eq(2)
    expect(rows[1]['area']).to eq('area2')
    expect(rows[1]['2020']).to eq(nil)
    expect(rows[1]['2025']).to eq(4)
    
  end

  it "should provide a density method" do
    setup_simple

    fact = DemographicFact.all[0]

    expect(fact.density).to eq(1)
  end

  it "should provide a range_select method" do
    setup_simple
    
    facts = DemographicFact.range_select(DemographicFact.all, nil, nil)

    expect(facts).to eq(DemographicFact.all)

    facts = DemographicFact.range_select(DemographicFact.all, 1, nil)

    expect(facts).to eq(DemographicFact.all)

    facts = DemographicFact.range_select(DemographicFact.all, 2, nil)

    expect(facts.count).to eq(2)
    
    facts = DemographicFact.range_select(DemographicFact.all, nil, 2)
    
    expect(facts.count).to eq(2)

    facts = DemographicFact.range_select(DemographicFact.all, 1, 2)
    
    expect(facts.count).to eq(2)

    facts = DemographicFact.range_select(DemographicFact.all, 1, 4)
    
    expect(facts.count).to eq(3)

    facts = DemographicFact.range_select(DemographicFact.all, 5, 6)
    
    expect(facts.count).to eq(0)

  end
    
  it "should produce a pivot table with non-default :value_name" do
    setup_simple
    @view.update_attributes(value_name: :density)
    
    rows = DemographicFact.pivot(@view)

    expect(rows.count).to eq(2)
    expect(rows[0]['area']).to eq('area')
    expect(rows[0]['2020']).to eq(1)
    expect(rows[0]['2025']).to eq(2)
    expect(rows[1]['area']).to eq('area2')
    expect(rows[1]['2020']).to eq(nil)
    expect(rows[1]['2025']).to eq(2)
    
  end

  it "should allow data gaps in the pivot table" do
    setup_simple

    @fact.destroy

    rows = DemographicFact.pivot(@view)

    expect(rows.count).to eq(2)
    expect(rows[0]['area']).to eq('area')
    expect(rows[0]['2020']).to eq(nil)
    expect(rows[0]['2025']).to eq(2)
    expect(rows[1]['area']).to eq('area2')
    expect(rows[1]['2020']).to eq(nil)
    expect(rows[1]['2025']).to eq(4)
    
  end

  it "should only show data for the main view" do
    main = View.find_or_create_by( name: "Main", data_model: CountFact )
    other = View.find_or_create_by( name: "Other", data_model: CountFact )
    
    area = Area.find_or_create_by( name: "area" )
    stat = Statistic.find_or_create_by( name: "Pop" )
    main.update_attributes(columns: ['area', '2020', '2025'])

    fact = DemographicFact.where(view_id: main, 
                                 year: 2020, 
                                 area_id: area, 
                                 statistic_id: stat).first_or_create
    fact.update_attributes(value: 1)
    fact = DemographicFact.where(view_id: main, 
                                 year: 2025, 
                                 area_id: area,
                                 statistic_id: stat).first_or_create
    fact.update_attributes(value: 2)

    fact = DemographicFact.where(view_id: other, 
                                 year: 2020, 
                                 area_id: area, 
                                 statistic_id: stat).first_or_create
    fact.update_attributes(value: 10)
    fact = DemographicFact.where(view_id: other, 
                                 year: 2025, 
                                 area_id: area,
                                 statistic_id: stat).first_or_create
    fact.update_attributes(value: 20)

    rows = DemographicFact.pivot(main)

    expect(rows.count).to eq(1)
    expect(rows[0]['area']).to eq('area')
    expect(rows[0]['2020']).to eq(1)
    expect(rows[0]['2025']).to eq(2)
    
  end

  it "should be able to find a demographic CSV file" do
    CSV.foreach('db/AllPopulation2020.csv', headers: true) do |row|
      
    end
  end

  it "should be able to read in a csv file" do
    DemographicFact.loadCSV('db/AllPopulation2020.csv', @view, nil)

  end

  it "should be able to loadCSV a csv file creating areas as needed" do
    DemographicFact.loadCSV('db/AllPopulation2020.csv', @view, nil, 'subregion', 'county')

    expect(Area.count).to be >= 36

    nyc = Area.find_by_name('New York City')
    expect(nyc).not_to be_nil
    expect(nyc.enclosed_areas.count).to eq(5)
    expect(nyc.type).to eq('subregion')
    
    bronx = Area.find_by_name('Bronx')
    expect(bronx).not_to be_nil
    expect(nyc.enclosed_areas.first).to eq(bronx)
    expect(bronx.type).to eq('county')
  end

  it "should be able loadCSV a csv file" do
    stat = Statistic.find_or_create_by( name: "Population" )
    stat.update_attributes(scale: 3)
    
    DemographicFact.loadCSV('db/AllPopulation2020.csv', @view, stat)

    expect(DemographicFact.all.count).to be >= 31 * 9
  end

end
