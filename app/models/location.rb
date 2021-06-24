class Location < ActiveRecord::Base
  belongs_to :sector

  def to_s
    name
  end
end
