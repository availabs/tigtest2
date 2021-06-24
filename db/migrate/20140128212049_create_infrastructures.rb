class CreateInfrastructures < ActiveRecord::Migration
  def change
    create_table :infrastructures do |t|
      t.string :name

      t.timestamps
    end
    add_index :infrastructures, :name
  end
end
