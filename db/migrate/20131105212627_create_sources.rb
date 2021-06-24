class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :name
      t.text :description
      t.integer :current_version
      t.datetime :date_starts_at
      t.datetime :date_ends_at
      t.string :origin_url
      t.integer :user_id
      t.datetime :rows_updated_at
      t.integer :rows_updated_by_id
      t.string :topic_area
      t.string :source_type

      t.timestamps
    end
  end
end
