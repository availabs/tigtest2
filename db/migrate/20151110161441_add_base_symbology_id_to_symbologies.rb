class AddBaseSymbologyIdToSymbologies < ActiveRecord::Migration
  def change
    add_column :symbologies, :base_symbology_id, :integer
  end
end
