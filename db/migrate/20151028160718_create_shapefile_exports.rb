class CreateShapefileExports < ActiveRecord::Migration
  def change
    create_table :shapefile_exports do |t|
      t.references :view, index: true
      t.references :delayed_job, index: true
      t.string :file_path

      t.timestamps
    end
  end
end
