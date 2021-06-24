class CreateSponsors < ActiveRecord::Migration
  def change
    create_table :sponsors do |t|
      t.string :name

      t.timestamps
    end
    add_index :sponsors, :name
  end
end
