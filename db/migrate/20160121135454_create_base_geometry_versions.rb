class CreateBaseGeometryVersions < ActiveRecord::Migration
  def change
    create_table :base_geometry_versions do |t|
      t.string :category
      t.string :version

      t.timestamps
    end
  end
end
