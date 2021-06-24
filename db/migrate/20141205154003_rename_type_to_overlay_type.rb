class RenameTypeToOverlayType < ActiveRecord::Migration
  def change
    rename_column :base_overlays, :type, :overlay_type
  end
end
