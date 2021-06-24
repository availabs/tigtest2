class CreateSpeedFacts < ActiveRecord::Migration
  def change
    create_table :speed_facts do |t|
      t.references :tmc, index: true
      t.integer :year
      t.integer :month
      t.integer :day_of_week, default: 0
      t.integer :hour
      t.references :road, index: true
      t.integer :vehicle_class, default: 0
      t.string :direction
      t.references :area, index: true
      t.integer :speed

      t.timestamps
    end
    add_index :speed_facts, :year
    add_index :speed_facts, :month
    add_index :speed_facts, :day_of_week
    add_index :speed_facts, :hour
    add_index :speed_facts, :vehicle_class
    add_index :speed_facts, :direction
  end
end
