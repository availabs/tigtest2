class SetBaseGeometrySrid < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute "SELECT UpdateGeometrySRID('base_geometries','geom',4326);"
  end
end
