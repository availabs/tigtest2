class CreateTipProjects < ActiveRecord::Migration
  def change
    create_table :tip_projects do |t|
      t.text :geography
      t.references :view, index: true
      t.string :tip_id
      t.references :ptype, index: true
      t.float :cost
      t.references :mpo, index: true
      t.integer :county_id
      t.references :sponsor, index: true
      t.text :description

      t.timestamps
    end
    add_index :tip_projects, :tip_id
    add_index :tip_projects, :county_id
  end
end
