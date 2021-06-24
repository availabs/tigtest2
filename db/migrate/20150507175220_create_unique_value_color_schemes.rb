class CreateUniqueValueColorSchemes < ActiveRecord::Migration
  def change
    create_table :unique_value_color_schemes do |t|
      t.string :color, null: false
      t.string :value, null: false

      t.timestamps
    end
  end
end
