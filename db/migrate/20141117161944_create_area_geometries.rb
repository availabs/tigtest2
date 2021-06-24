class CreateAreaGeometries < ActiveRecord::Migration
  def change
    create_table :area_geometries do |t|
      t.references :area
      t.geometry :geom

      t.timestamps
    end
  end
end
