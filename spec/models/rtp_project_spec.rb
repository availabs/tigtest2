require 'spec_helper'
require 'csv'

describe RtpProject, :type => :model do
  before(:each) do
    @view = View.find_or_create_by( name: "view" )
  end

  describe "should work as a data_model" do

    it "should be a valid attribute for a View" do
      @view.data_model = RtpProject

      @view.save if @view.changed?

      @view = View.find_by_name('view')

      expect(@view.data_model).to eq(RtpProject)

      expect(@view.data_model).to respond_to(:all)

      expect(@view.data_model.pivot?).to eq(false)
    end
  end

  it "should create new dimensions as needed" do
    dims = ['PlanPortion', 'Sponsor', 'Ptype']
    dims.each do |name|
      dim = RtpProject.getDimension(name, 'value')

      expect(dim).not_to be_nil
      dimClass = name.constantize
      expect(dimClass.find_by_name('value')).to eq(dim)
    end

    notDims = ['Description', 'EstimatedCost', 'Geography', 'RTP_ID', 'Year']
    notDims.each do |name|
      expect { RtpProject.getDimension(name, nil) }.to raise_error(NameError)
    end
    
  end
  
  it "should be able to read in a csv file" do
    RtpProject.loadCSV('db/point_proj.csv', @view)
  end

  it "should be able to loadCSV a csv file creating dimensions as needed" do
    RtpProject.loadCSV('db/point_proj.csv', @view)

    expect(PlanPortion.count).to eq(2)
    expect(Sponsor.count).to be > 0
    expect(Ptype.count).to be > 0
  end

  it "should be able loadCSV a csv file" do
    RtpProject.loadCSV('db/point_proj.csv', @view)

    expect(RtpProject.all.count).to be >= 125
  end

  it "should be able to apply an area filter" do
    RtpProject.loadCSV('db/point_proj.csv', @view)

    subregion = Area.find_or_create_by( name: 'Long Island' )
    county = Area.find_or_create_by( name: 'Suffolk', type: 'county' )
    county.enclosing_areas << subregion
    county.save!

    expect(RtpProject.apply_area_filter(@view, nil, nil).count).to eq(RtpProject.where(view_id: @view).count)
    expect(RtpProject.apply_area_filter(@view, county, 'project').count).to eq(RtpProject.where(view_id: @view, county_id: county).count)
    expect(RtpProject.apply_area_filter(@view, subregion, 'project').count).to eq(RtpProject.joins(county: :areas_enclosing).where(view_id: @view, area_enclosures: {enclosing_area_id: subregion}).count)
  end
    
end
