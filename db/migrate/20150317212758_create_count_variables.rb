class CreateCountVariables < ActiveRecord::Migration
  def change
    create_table :count_variables do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end
