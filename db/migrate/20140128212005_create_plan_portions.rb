class CreatePlanPortions < ActiveRecord::Migration
  def change
    create_table :plan_portions do |t|
      t.string :name

      t.timestamps
    end
    add_index :plan_portions, :name
  end
end
