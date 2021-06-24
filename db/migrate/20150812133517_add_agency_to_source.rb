class AddAgencyToSource < ActiveRecord::Migration
  def change
    add_column :sources, :agency_id, :integer
  end
end
