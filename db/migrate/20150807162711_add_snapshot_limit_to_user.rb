class AddSnapshotLimitToUser < ActiveRecord::Migration
  def change
    add_column :users, :snapshot_limit, :integer, default: 10
  end
end
