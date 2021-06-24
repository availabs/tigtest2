require 'spec_helper'
require 'csv'

describe Area, :type => :model do

  before(:each) do
    @area = Area.new(name: "Test Area")
  end

  describe "base behavior" do
    it "should have no enclosed or enclosing areas initially" do
      expect(@area.enclosing_areas).to be_empty
      expect(@area.enclosed_areas).to be_empty
    end

    it "should appear in an enclosing area's enclosed areas" do
      @outer = Area.new(name: "Outer")
      @area.enclosing_areas << @outer
      @area.save!

      expect(@area.enclosing_areas.count).to eq(1)
      expect(@outer.enclosed_areas.count).to eq(1)

      expect(@area.enclosing_areas).to include(@outer)
      expect(@outer.enclosed_areas).to include(@area)
    end

    it "should appear in an enclosed area's enclosing areas" do
      @inner = Area.new(name: "Outer")
      @area.enclosed_areas << @inner
      @area.save!

      expect(@inner.enclosing_areas.count).to eq(1)
      expect(@area.enclosed_areas.count).to eq(1)

      expect(@area.enclosed_areas).to include(@inner)
      expect(@inner.enclosing_areas).to include(@area)
    end
  end

  describe "size behavior" do
    it "should default to nil" do
      expect(@area.size).to be_nil
    end

    it "should be settable" do
      @area.update_attributes(size: 1.0)
      @area = Area.find(@area.id)

      expect(@area.size).to eq(1.0)
    end
    
    it "should be loadable from csv" do
      Area.loadCSV('db/area_size.csv')

      expect(Area.count).to be >= 36

      Area.all.each do |area|
        expect(area.size).not_to be_nil
        expect(area.size).to be > 0
        expect(area.size).to be < 100000
      end
    end
    
  end

  describe "::parse" do
    valid_strings = {
      "Census Tract 1, Test Area County, State1" => "Test Area:1",
      "Census Tract 2, Test Area County, State1" => "Test Area:2",
      "Census Tract 3.01, Test Area County, State1" => "Test Area:3.01",
    }
    valid_strings.each do |k, v|
      specify "\"#{k}\" => \"#{v}\"" do
        @area.type = 'county'
        @area.save

        area = Area.parse(k, :census_tract)

        expect(area).not_to be_nil
        expect(area.name).to eq(v)
        expect(area.type).to eq('census_tract')
        expect(area.enclosing_areas).to include @area
        expect(@area.enclosed_areas).to include area

        # parse againto make sure enclosing areas handled correctly        
        area = Area.parse(k, :census_tract)

      end
    end

    it "should handle invalid data"
    
    it "should handle multiple states"

  end
end
