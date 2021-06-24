class CreateMpos < ActiveRecord::Migration
  def change
    create_table :mpos do |t|
      t.string :name

      t.timestamps
    end
  end
end
