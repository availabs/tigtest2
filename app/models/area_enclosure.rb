class AreaEnclosure < ActiveRecord::Base
  belongs_to :enclosing_area, foreign_key: :enclosing_area_id, class_name: "Area"
  belongs_to :enclosed_area, foreign_key: :enclosed_area_id, class_name: "Area"
end
