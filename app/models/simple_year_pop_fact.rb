class SimpleYearPopFact < ActiveRecord::Base
  attr_accessible :area_name, :pop_2000, :pop_2005, :pop_2010, :pop_2015, :pop_2020, :pop_2025, :pop_2030, :pop_2035, :pop_2040

  def self.pivot?
  end

end
