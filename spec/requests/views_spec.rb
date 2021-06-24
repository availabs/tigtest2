require 'spec_helper'

describe "Views", type: :request do
  it "GET /views" do
    skip "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get views_path
      expect(response.status).to be(200)
    end
  end
end
