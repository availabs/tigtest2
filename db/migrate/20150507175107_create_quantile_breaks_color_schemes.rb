class CreateQuantileBreaksColorSchemes < ActiveRecord::Migration
  def change
    create_table :quantile_breaks_color_schemes do |t|
      t.string :start_color, null: false
      t.string :end_color, null: false
      t.integer :class_count, null: false

      t.timestamps
    end
  end
end
