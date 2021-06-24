require 'spec_helper'

describe SimplePopulationFact, :type => :model do

  describe "should work as a data_model" do

    it "should be a valid attribute for a View" do
      @view = View.new(name: 'view')

      @view.data_model = SimplePopulationFact

      @view.save if @view.changed?

      @view = View.find_by_name('view')

      expect(@view.data_model).to eq(SimplePopulationFact)

      expect(@view.data_model).to respond_to(:all)
    end
  end
end
