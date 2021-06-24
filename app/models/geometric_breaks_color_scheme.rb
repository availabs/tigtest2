class GeometricBreaksColorScheme < ActiveRecord::Base
  validates :start_color, presence: true
  validates :end_color, presence: true
  validates :gap_value, presence: true

  belongs_to :symbology

  def as_json
    {
      start_color: start_color,
      end_color: end_color,
      gap_value: gap_value,
      multiplier: multiplier
    }
  end
end
