class AddBaseGeometryRefToSpeedFacts < ActiveRecord::Migration
  def change
    add_reference :speed_facts, :base_geometry, index: true
  end
end
