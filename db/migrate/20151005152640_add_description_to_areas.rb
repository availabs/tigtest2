class AddDescriptionToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :description, :text
  end
end
