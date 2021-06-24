class AddNameToBaseOverlays < ActiveRecord::Migration
  def change
    add_column :base_overlays, :name, :string
  end
end
