class AddShortDescriptionToSources < ActiveRecord::Migration
  def change
    add_column :sources, :short_description, :text
  end
end
