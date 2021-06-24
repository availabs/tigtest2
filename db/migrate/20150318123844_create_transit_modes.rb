class CreateTransitModes < ActiveRecord::Migration
  def change
    create_table :transit_modes do |t|
      t.string :name
      t.string :type
      t.string :group

      t.timestamps
    end
  end
end
