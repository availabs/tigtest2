class RenameAreaGeometriesToBaseGeometries < ActiveRecord::Migration
  def change
    rename_table :area_geometries, :base_geometries
  end
end
