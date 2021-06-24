class ChangeColumnsInCustomBreaksColorScheme < ActiveRecord::Migration
  def change
    change_column :custom_breaks_color_schemes, :min_value, :float, :null => true
    change_column :custom_breaks_color_schemes, :max_value, :float, :null => true
  end
end
