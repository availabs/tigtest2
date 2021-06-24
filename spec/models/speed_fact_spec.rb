require 'spec_helper'

RSpec.describe SpeedFact, :type => :model do
  before(:each) do
    @view = View.find_or_create_by( name: "view" )
    @tmc1 = Tmc.find_or_create_by(name: 'tmc1')
    @tmc2 = Tmc.find_or_create_by(name: 'tmc2')

    @view.update_attributes(data_model: SpeedFact)
  end

  describe "dynamic columns" do
    it "should provide dynamic columns" do
      expect(@view.columns).not_to be_empty
      expect(@view.columns).to eq(['tmc', 'road_name', 'road_number', 'direction'] + (1..24).collect {|h| h.to_s})
    end
    it "should provide dynamic column_labels" do
      expect(@view.column_labels).not_to be_empty
      expect(@view.column_labels[0..3]).to eq(['TMC', 'Roadway Name', 'Roadway Number', 'Direction'])
      expect(@view.column_labels[4..-1]).to eq((1..24).collect{|h| format('%02d:00', h-1)})
    end
    it "should provide dynamic column_types" do
      expect(@view.column_types).not_to be_empty
      expect(@view.column_types[4..-1]).to eq(['numeric']*24)
    end
  end
    
end
