class AddBaseOverlayToBaseGeometry < ActiveRecord::Migration
  def change
    add_reference :base_geometries, :base_overlay, index: true
  end
end
