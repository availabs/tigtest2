class AddCounterToUpwpProjects < ActiveRecord::Migration
  def change
    add_column :upwp_projects, :num_contracts, :integer
  end
end
