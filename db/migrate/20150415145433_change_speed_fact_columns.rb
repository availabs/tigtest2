class ChangeSpeedFactColumns < ActiveRecord::Migration
  def up
    change_table :speed_facts do |t|
      t.remove_index :base_geometry_id
      t.remove_index :direction

      t.change :year, :integer, limit: 2
      t.change :month, :integer, limit: 1
      t.change :day_of_week, :integer, limit: 1
      t.change :hour, :integer, limit: 1
      t.change :speed, :integer, limit: 1
    end
  end

  def down
    change_table :speed_facts do |t|
      t.change :year, :integer
      t.change :month, :integer
      t.change :day_of_week, :integer
      t.change :hour, :integer
      t.change :speed, :integer
      
      t.index :base_geometry_id
      t.index :direction
    end
  end
  
end
