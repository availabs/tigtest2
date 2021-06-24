class CreateUpwpRelatedContracts < ActiveRecord::Migration
  def change
    create_table :upwp_related_contracts do |t|
      t.references :view, index: true
      t.references :upwp_project, index: true
      t.string :contract_project_id
      t.string :name
      t.integer :program_year
      t.integer :actual_programmed_year
      t.integer :budgeted_consultant_cost
      t.text :detail
      t.integer :fhwa_carryover
      t.integer :fta_carryover

      t.timestamps
    end
  end
end
