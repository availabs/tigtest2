class AddCountVariableTransitModeTable < ActiveRecord::Migration
  def change
    create_table :count_variables_transit_modes, id: false do |t|
      t.references :count_variable, index: true
      t.references :transit_mode, index: true
    end
  end
end
