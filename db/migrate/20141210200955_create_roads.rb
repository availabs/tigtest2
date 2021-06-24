class CreateRoads < ActiveRecord::Migration
  def change
    create_table :roads do |t|
      t.string :name
      t.string :number

      t.timestamps
    end
  end
end
