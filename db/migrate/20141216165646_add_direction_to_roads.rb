class AddDirectionToRoads < ActiveRecord::Migration
  def change
    add_column :roads, :direction, :string
  end
end
