class AddGeometryVersionToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :geometry_version, :string
  end
end
