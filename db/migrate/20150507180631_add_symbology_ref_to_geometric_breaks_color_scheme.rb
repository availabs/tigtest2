class AddSymbologyRefToGeometricBreaksColorScheme < ActiveRecord::Migration
  def change
    add_reference :geometric_breaks_color_schemes, :symbology, index: true
  end
end
