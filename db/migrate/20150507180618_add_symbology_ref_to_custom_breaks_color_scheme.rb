class AddSymbologyRefToCustomBreaksColorScheme < ActiveRecord::Migration
  def change
    add_reference :custom_breaks_color_schemes, :symbology, index: true
  end
end
