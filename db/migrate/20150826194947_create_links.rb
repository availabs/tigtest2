class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.references :area, index: true
      t.string :direction
      t.references :road, index: true
      t.integer :speed_limit
      t.integer :length
      t.references :base_geometry, index: true

      t.timestamps
    end
    change_column :links, :id, :integer, limit: 8
  end
end
