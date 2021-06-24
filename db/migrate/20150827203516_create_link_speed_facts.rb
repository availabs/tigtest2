class CreateLinkSpeedFacts < ActiveRecord::Migration
  def change
    create_table :link_speed_facts do |t|
      t.references :view, index: true
      t.references :link, index: true
      t.integer :year, limit: 2
      t.integer :month, limit: 2
      t.integer :day_of_week, limit: 2, default: 0
      t.integer :hour, limit: 2
      t.references :road, index: true
      t.string :direction
      t.references :area, index: true
      t.references :base_geometry, index: true
      t.integer :speed, limit: 2

      t.timestamps
    end
    add_index :link_speed_facts, :year
    add_index :link_speed_facts, :month
    add_index :link_speed_facts, :day_of_week
    add_index :link_speed_facts, :hour
  end
end
