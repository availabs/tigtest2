class AddLabelToCustomBreaksColorScheme < ActiveRecord::Migration
  def change
    add_column :custom_breaks_color_schemes, :label, :string
  end
end
