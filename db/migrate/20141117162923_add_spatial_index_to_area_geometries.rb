class AddSpatialIndexToAreaGeometries < ActiveRecord::Migration
  def change
    add_index :area_geometries, :geom, spatial: true
  end
end
