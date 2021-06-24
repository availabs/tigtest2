class AddTmpShapefileReferenceToShapefileExport < ActiveRecord::Migration
  def change
    add_reference :shapefile_exports, :tmp_shapefile, index: true
  end
end
