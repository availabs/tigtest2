class AddSymbologyRefToNaturalBreaksColorScheme < ActiveRecord::Migration
  def change
    add_reference :natural_breaks_color_schemes, :symbology, index: true
  end
end
