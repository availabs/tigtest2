class TransitMode < ActiveRecord::Base
  # by default ActiveRecord uses type for single record inheritance. Disable for now.
  TransitMode.inheritance_column = 'none'

  has_and_belongs_to_many :count_variables

  def to_s
    name
  end
end
