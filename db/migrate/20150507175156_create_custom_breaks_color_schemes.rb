class CreateCustomBreaksColorSchemes < ActiveRecord::Migration
  def change
    create_table :custom_breaks_color_schemes do |t|
      t.string :color, null: false
      t.float :min_value, null: false
      t.float :max_value, null: false

      t.timestamps
    end
  end
end
