class NaturalBreaksColorScheme < ActiveRecord::Base
  validates :start_color, presence: true
  validates :end_color, presence: true
  validates :class_count, presence: true

  belongs_to :symbology

  def as_json
    {
      start_color: start_color,
      end_color: end_color,
      class_count: class_count
    }
  end
end
