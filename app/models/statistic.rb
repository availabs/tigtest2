# This class captures simple types of statistics and the 
# scaling factor used to store the value.
# For example {name: 'population', scale: 3}
# indicates a population value measured in thousands.
class Statistic < ActiveRecord::Base
  attr_accessible :name, :scale

  has_many :views

  def caption
    if scale && scale > 0
      "#{name} (in #{'0'*scale}s)"
    else
      name
    end
  end
end
