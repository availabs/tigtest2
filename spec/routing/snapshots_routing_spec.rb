require "spec_helper"

RSpec.describe SnapshotsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/snapshots").to route_to("snapshots#index")
    end

    it "routes to #new" do
      expect(:get => "/snapshots/new").to route_to("snapshots#new")
    end

    it "routes to #show" do
      expect(:get => "/snapshots/1").to route_to("snapshots#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/snapshots/1/edit").to route_to("snapshots#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/snapshots").to route_to("snapshots#create")
    end

    it "routes to #update" do
      expect(:put => "/snapshots/1").to route_to("snapshots#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/snapshots/1").to route_to("snapshots#destroy", :id => "1")
    end

  end
end
