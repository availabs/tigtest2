class AddColumnsToView < ActiveRecord::Migration
  def change
    add_column :views, :row_name, :string
    add_column :views, :column_name, :string
  end
end
