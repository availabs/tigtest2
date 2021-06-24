class MakeSnapshotsShareable < ActiveRecord::Migration
  def change
    add_column :snapshots, :published, :boolean, default: false
    create_table :viewers_snapshots, id: false do |t|
      t.references :user, index: true
      t.references :snapshot, index: true
    end
  end
end
