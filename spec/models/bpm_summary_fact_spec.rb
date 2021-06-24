require 'spec_helper'
require 'csv'

describe BpmSummaryFact, :type => :model do
  before(:each) do
    @view = View.find_or_create_by( name: "view" )
  end

  describe "should work as a data_model" do

    it "should be a valid attribute for a View" do
      @view.data_model = BpmSummaryFact

      @view.save if @view.changed?

      @view = View.find_by_name('view')

      expect(@view.data_model).to eq(BpmSummaryFact)

      expect(@view.data_model).to respond_to(:all)

      expect(@view.data_model.pivot?).to eq(false)
    end
  end

  it "should be able to parse headers" do
    attributes = BpmSummaryFact.parse_header('origWorkDA')
    expect(attributes[:orig_dest]).to eq('orig')
    expect(attributes[:purpose]).to eq('Work')
    expect(attributes[:mode]).to eq('DA')
    
    attributes = BpmSummaryFact.parse_header('destNonWorkSB')
    expect(attributes[:orig_dest]).to eq('dest')
    expect(attributes[:purpose]).to eq('NonWork')
    expect(attributes[:mode]).to eq('SB')
    
  end
  
  it "should be able to read in a csv file" do
    BpmSummaryFact.loadCSV('db/taz_summaries_test.csv', @view, 2020)
  end

  it "should be able loadCSV a csv file" do
    BpmSummaryFact.loadCSV('db/taz_summaries_test.csv', @view, 2020)

    # 3 rows * 2 od * 2 purpose * 11 modes
    expect(BpmSummaryFact.count).to be >= 132
  end

  it "should be able to apply an area filter" do
    BpmSummaryFact.loadCSV('db/taz_summaries_test.csv', @view, 2020)

    subregion = Area.find_or_create_by( name: 'Long Island' )
    county = Area.find_or_create_by( name: 'Suffolk' )
    county.enclosing_areas << subregion
    county.save!

    expect(BpmSummaryFact.apply_area_filter(@view, nil, nil).count).to eq(BpmSummaryFact.where(view_id: @view).count)
    expect(BpmSummaryFact.apply_area_filter(@view, county, nil).count).to eq(BpmSummaryFact.joins(area: :areas_enclosing).where(view_id: @view, area_enclosures: {enclosing_area_id: county}).count)
  end
  
end
