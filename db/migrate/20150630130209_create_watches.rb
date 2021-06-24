class CreateWatches < ActiveRecord::Migration
  def change
    create_table :watches do |t|
      t.integer :user_id
      t.integer :source_id
      t.integer :view_id
      t.datetime :last_seen_at
      t.datetime :last_triggered_at

      t.timestamps
    end
  end
end
