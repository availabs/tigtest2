class CreateStatistics < ActiveRecord::Migration
  def change
    create_table :statistics do |t|
      t.string :name
      t.integer :scale

      t.timestamps
    end
  end
end
