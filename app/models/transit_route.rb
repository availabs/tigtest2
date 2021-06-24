class TransitRoute < ActiveRecord::Base
  belongs_to :transit_agency

  def to_s
    name
  end
  
end
