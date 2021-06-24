class AddUserReferenceToShapefileExports < ActiveRecord::Migration
  def change
    add_reference :shapefile_exports, :user, index: true
  end
end
