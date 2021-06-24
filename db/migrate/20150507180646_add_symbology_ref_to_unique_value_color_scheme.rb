class AddSymbologyRefToUniqueValueColorScheme < ActiveRecord::Migration
  def change
    add_reference :unique_value_color_schemes, :symbology, index: true
  end
end
