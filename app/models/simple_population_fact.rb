class SimplePopulationFact < ActiveRecord::Base
  attr_accessible :area_name, :population

  def self.pivot?
  end

end
