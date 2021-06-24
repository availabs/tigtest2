class CreateSymbologies < ActiveRecord::Migration
  def change
    create_table :symbologies do |t|
      t.string :subject, null: false
      t.integer :default_column_index
      t.boolean :show_legend, default: true
      t.string :symbology_type

      t.timestamps
    end
  end
end
