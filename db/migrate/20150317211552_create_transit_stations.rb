class CreateTransitStations < ActiveRecord::Migration
  def change
    create_table :transit_stations do |t|
      t.string :name

      t.timestamps
    end
  end
end
