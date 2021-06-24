class RemoveColumnsFromTmc < ActiveRecord::Migration
  def change
    remove_column :tmcs, :direction, :string
    remove_column :tmcs, :road_id, :integer
    remove_column :tmcs, :area_id, :integer
  end
end
