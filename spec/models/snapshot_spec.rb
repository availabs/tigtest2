require 'spec_helper'

RSpec.describe Snapshot, :type => :model do
  
  before(:each) do
    @snapshot = FactoryGirl.create(:snapshot)
  end

  it "should create a new instance given valid attributes" do
    expect(@snapshot).to be_valid
  end

  it "should require a user" do
    @snapshot.user = nil
    expect(@snapshot).not_to be_valid 
  end

  it "should require a view" do
    @snapshot.view_id = nil
    expect(@snapshot).not_to be_valid 
  end

  it "should require a name" do
    @snapshot.name = nil
    expect(@snapshot).not_to be_valid 
  end

  it "should not require a description" do
    @snapshot.description = nil
    expect(@snapshot).to be_valid
  end

  it "should not require an area" do
    @snapshot.area_id = nil
    expect(@snapshot).to be_valid
  end

  it "should not require an upper range" do
    @snapshot.range_high = nil
    expect(@snapshot).to be_valid
  end

  it "should not require an lower range" do
    @snapshot.range_low = nil
    expect(@snapshot).to be_valid
  end

  it "should not require filters" do
    @snapshot.filters = nil
    expect(@snapshot).to be_valid
  end

  it "should not require table settings" do
    @snapshot.table_settings = nil
    expect(@snapshot).to be_valid
  end

  it "should not require map settings" do
    @snapshot.map_settings = nil
    expect(@snapshot).to be_valid
  end
end
