class CreateGeometricBreaksColorSchemes < ActiveRecord::Migration
  def change
    create_table :geometric_breaks_color_schemes do |t|
      t.string :start_color, null: false
      t.string :end_color, null: false
      t.float :gap_value, null: false
      t.float :multiplier

      t.timestamps
    end
  end
end
