class AddAreaIndexToBaseGeometry < ActiveRecord::Migration
  def change
    add_index :base_geometries, :area_id
  end
end
