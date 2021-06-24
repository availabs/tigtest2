class CreateTmcs < ActiveRecord::Migration
  def change
    create_table :tmcs do |t|
      t.string :name
      t.references :base_geometry, index: true
      t.string :direction, index: true
      t.references :road, index: true
      t.references :area, index: true

      t.timestamps
    end
  end
end
