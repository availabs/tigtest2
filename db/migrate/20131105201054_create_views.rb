class CreateViews < ActiveRecord::Migration
  def change
    create_table :views do |t|
      t.string :name
      t.text :description
      t.integer :source_id
      t.integer :current_version
      t.datetime :date_starts_at
      t.datetime :date_ends_at
      t.string :origin_url
      t.integer :user_id
      t.datetime :rows_updated_at
      t.integer :rows_updated_by_id
      t.string :topic_area
      t.integer :download_count
      t.datetime :last_displayed_at
      t.integer :view_count

      t.timestamps
    end
  end
end
