class AddColumnsToViews < ActiveRecord::Migration
  def change
    add_column :views, :columns, :text
  end
end
