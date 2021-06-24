class FixeDataStartEnd < ActiveRecord::Migration
  def change
    rename_column :sources, :date_starts_at, :data_starts_at
    rename_column :sources, :date_ends_at, :data_ends_at
    rename_column :views, :date_starts_at, :data_starts_at
    rename_column :views, :date_ends_at, :data_ends_at
  end
end
