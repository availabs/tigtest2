class CreateUpwpProjects < ActiveRecord::Migration
  def change
    create_table :upwp_projects do |t|
      t.references :view, index: true
      t.integer :year
      t.string :project_id
      t.string :name
      t.references :project_category, index: true
      t.references :sponsor, index: true
      t.string :agency_code
      t.text :description
      t.float :total_staff_cost
      t.integer :total_consultant_cost
      t.integer :budgeted_other_cost
      t.text :deliverables

      t.timestamps
    end
  end
end
