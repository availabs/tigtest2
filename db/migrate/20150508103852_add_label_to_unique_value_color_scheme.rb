class AddLabelToUniqueValueColorScheme < ActiveRecord::Migration
  def change
    add_column :unique_value_color_schemes, :label, :string
  end
end
