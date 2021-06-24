class AddColumnLabelsToViews < ActiveRecord::Migration
  def change
    add_column :views, :column_labels, :text
  end
end
