class AddDataLevelsToView < ActiveRecord::Migration
  def change
    add_column :views, :data_levels, :text
  end
end
