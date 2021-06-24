class RemoveEnclosingAreaIdFromAreas < ActiveRecord::Migration
  def change
    remove_column  :areas, :enclosing_area_id, :integer
  end
end
