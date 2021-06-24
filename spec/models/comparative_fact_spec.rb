require 'spec_helper'

describe ComparativeFact, type: :model do

  before(:each) do
    @view = View.find_or_create_by( name: "view" )
  end

  describe "should work as a data_model" do

    it "should be a valid attribute for a View" do
      @view.data_model = ComparativeFact
      @view.save if @view.changed?

      @view = View.find_by_name('view')

      expect(@view.data_model).to eq(ComparativeFact)

      expect(@view.data_model).to respond_to(:all)
    end
  end

  def setup
    @area = Area.find_or_create_by( name: "area" )
    @area2 = Area.find_or_create_by( name: "area2" )
    @area2.enclosing_areas << @area
    @area3 = Area.find_or_create_by( name: "area3" )
    @area3.enclosing_areas << @area
    
    base_stat = Statistic.find_or_create_by( name: "Pop" )
    stat = Statistic.find_or_create_by( name: "SubPop" )
    @view.update_attributes(columns: ['enclosing_area', 'area', 'base_value', 'value', 'percent'])

    @fact = ComparativeFact.where(view: @view, 
                                  area: @area2, 
                                  base_statistic: base_stat,
                                  statistic: stat).first_or_create
    @fact.update_attributes(base_value: 2, value: 1)

    @fact2 = ComparativeFact.where(view: @view, 
                                  area: @area3, 
                                  base_statistic: base_stat,
                                  statistic: stat).first_or_create
    @fact2.update_attributes(base_value: 10, value: 1)
  end

  it "should provide an enclosing_area" do
    setup
    expect(@fact.enclosing_area).to eq(@area)
  end

  it "should provide a percent value" do
    setup
    expect(@fact.percent).to eq(0.5)
  end

  it "should provide a range_select method" do
    setup

    value_column = :percent

    facts = ComparativeFact.range_select(ComparativeFact.all, nil, nil, value_column)

    expect(facts).to match_array(ComparativeFact.all)

    facts = ComparativeFact.range_select(ComparativeFact.all, 1, nil, value_column)

    expect(facts).to match_array(ComparativeFact.all)
    
    facts = ComparativeFact.range_select(ComparativeFact.all, 1, 60, value_column)

    expect(facts).to match_array(ComparativeFact.all)

    facts = ComparativeFact.range_select(ComparativeFact.all, nil, 60, value_column)

    expect(facts).to match_array(ComparativeFact.all)

    facts = ComparativeFact.range_select(ComparativeFact.all, 20, nil, value_column)

    expect(facts.count).to eq(1)

    facts = ComparativeFact.range_select(ComparativeFact.all, 20, 60, value_column)

    expect(facts.count).to eq(1)
    
    facts = ComparativeFact.range_select(ComparativeFact.all, 10, 40, value_column)

    expect(facts.count).to eq(1)

    facts = ComparativeFact.range_select(ComparativeFact.all, 55, 60, value_column)

    expect(facts.count).to eq(0)
  end
  
end
  
