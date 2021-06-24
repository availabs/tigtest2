class AddStatusToShapefileExports < ActiveRecord::Migration
  def change
    add_column :shapefile_exports, :status, :string
    add_column :shapefile_exports, :message, :string
  end
end
