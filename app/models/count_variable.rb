class CountVariable < ActiveRecord::Base
  has_and_belongs_to_many :transit_modes

  def to_s
    name
  end
end
