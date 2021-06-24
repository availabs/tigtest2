class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.integer :user_id
      t.string :name
      t.text :description
      t.integer :view_id
      t.integer :app
      t.integer :area_id
      t.integer :range_low
      t.integer :range_high

      t.timestamps
    end
  end
end
