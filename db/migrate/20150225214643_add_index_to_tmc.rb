class AddIndexToTmc < ActiveRecord::Migration
  def change
    add_column :tmcs, :index, :integer
    add_index :tmcs, :index, unique: true
  end
end
