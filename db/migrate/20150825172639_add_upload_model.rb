class AddUploadModel < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.references :view, index: true
      t.string :filename
      t.string :s3_location
      t.integer :year
      t.integer :month
      t.text :notes

      t.timestamps
    end
    add_column :views, :download_instructions, :text
  end
end
