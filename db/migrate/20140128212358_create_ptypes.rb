class CreatePtypes < ActiveRecord::Migration
  def change
    create_table :ptypes do |t|
      t.string :name

      t.timestamps
    end
    add_index :ptypes, :name
  end
end
