require "spec_helper"

describe ViewsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(get("/views")).to route_to("views#index")
    end

    it "routes to #new" do
      expect(get("/views/new")).to route_to("views#new")
    end

    it "routes to #show" do
      expect(get("/views/1")).to route_to("views#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/views/1/edit")).to route_to("views#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/views")).to route_to("views#create")
    end

    it "routes to #update" do
      expect(put("/views/1")).to route_to("views#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/views/1")).to route_to("views#destroy", :id => "1")
    end

  end
end
