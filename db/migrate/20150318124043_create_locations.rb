class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name
      t.references :sector, index: true
      t.float :latitude
      t.float :longitude
      t.string :surface_type

      t.timestamps
    end
  end
end
