class AddSymbologyRefToQuantileBreaksColorScheme < ActiveRecord::Migration
  def change
    add_reference :quantile_breaks_color_schemes, :symbology, index: true
  end
end
