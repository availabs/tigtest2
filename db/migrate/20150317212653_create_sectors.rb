class CreateSectors < ActiveRecord::Migration
  def change
    create_table :sectors do |t|
      t.string :name
      t.integer :counts
      t.integer :order

      t.timestamps
    end
  end
end
