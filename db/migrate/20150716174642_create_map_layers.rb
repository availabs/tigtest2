class CreateMapLayers < ActiveRecord::Migration
  def change
    create_table :map_layers do |t|
      t.string :title
      t.string :url
      t.string :name
      t.string :category
      t.string :layer_type
      t.string :geometry_type
      t.string :reference_column
      t.string :label_column
      t.boolean :visibility, default: true
      t.boolean :label_visibility, default: false
      t.string :version
      t.string :style
      t.string :highlight_style
      t.text :attribution
      t.text :predefined_symbology

      t.timestamps
    end
  end
end
