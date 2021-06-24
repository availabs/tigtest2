class CreatePerformanceMeasuresFacts < ActiveRecord::Migration
  def change
    create_table :performance_measures_facts do |t|
      t.references :view, index: true
      t.references :area, index: true
      t.integer :period, limit: 2, default: 0
      t.integer :functional_class, limit: 2, default: 0
      t.integer :vehicle_miles_traveled
      t.integer :vehicle_hours_traveled
      t.float :avg_speed

      t.timestamps
    end
    add_index :performance_measures_facts, :period
    add_index :performance_measures_facts, :functional_class
  end
end
