require 'spec_helper'

describe "add view", :type => :model do
  
  before(:each) do
    @source = Source.new(name: "Source 1")
  end

  it "should support add_view to create and attach a new view" do
    @view = @source.add_view("View 1")

    expect(@view).not_to be_nil
    expect(@view.name).to eql "View 1"

    expect(@source.views).to include(@view)
  end
end
