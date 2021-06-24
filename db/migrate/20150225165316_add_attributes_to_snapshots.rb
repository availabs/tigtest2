class AddAttributesToSnapshots < ActiveRecord::Migration
  def change
    add_column :snapshots, :filters, :text
    add_column :snapshots, :table_settings, :text
    add_column :snapshots, :map_settings, :text
  end
end
