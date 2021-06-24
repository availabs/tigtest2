class CustomBreaksColorScheme < ActiveRecord::Base
  validates :color, presence: true
  validate :value_exists

  belongs_to :symbology

  def as_json
    {
      color: color,
      min_value: min_value,
      max_value: max_value,
      label: label
    }
  end

  def label
    super || "#{min_value} - #{max_value}"
  end

  private 

  def value_exists
    min_value || max_value
  end
end
