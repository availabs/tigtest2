class AddColumnTypesToView < ActiveRecord::Migration
  def change
    add_column :views, :column_types, :text
  end
end
