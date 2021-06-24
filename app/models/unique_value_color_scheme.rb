class UniqueValueColorScheme < ActiveRecord::Base
  validates :color, presence: true
  validates :value, presence: true

  belongs_to :symbology

  def as_json
    {
      color: color,
      value: value,
      label: label || value
    }
  end
end
