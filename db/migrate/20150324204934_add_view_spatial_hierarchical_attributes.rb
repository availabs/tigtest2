class AddViewSpatialHierarchicalAttributes < ActiveRecord::Migration
  def change
    add_column :views, :spatial_level, :text
    add_column :views, :data_hierarchy, :text
  end
end
