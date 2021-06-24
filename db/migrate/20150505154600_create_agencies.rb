class CreateAgencies < ActiveRecord::Migration
  def change
    create_table :agencies do |t|
      t.string :name
      t.text :description
      t.string :url

      t.timestamps
    end
    add_column :users, :agency_id, :integer
  end
end
