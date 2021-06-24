class AddShortDescriptionToViews < ActiveRecord::Migration
  def change
    add_column :views, :short_description, :text
  end
end
