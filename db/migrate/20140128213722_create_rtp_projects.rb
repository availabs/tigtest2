class CreateRtpProjects < ActiveRecord::Migration
  def change
    create_table :rtp_projects do |t|
      t.text :geography
      t.references :plan_portion
      t.references :infrastructure
      t.string :rtp_id_201
      t.references :project_category
      t.text :description
      t.references :sponsor
      t.references :ptype
      t.integer :year
      t.float :estimated_cost
      t.references :county

      t.timestamps
    end
    add_index :rtp_projects, :plan_portion_id
    add_index :rtp_projects, :infrastructure_id
    add_index :rtp_projects, :project_category_id
    add_index :rtp_projects, :sponsor_id
    add_index :rtp_projects, :ptype_id
    add_index :rtp_projects, :county_id
  end
end
