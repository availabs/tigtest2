class AddValueColumnsToViews < ActiveRecord::Migration
  def change
    add_column :views, :value_columns, :text
  end
end
