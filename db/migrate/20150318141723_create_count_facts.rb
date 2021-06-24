class CreateCountFacts < ActiveRecord::Migration
  def change
    create_table :count_facts do |t|
      t.integer :year
      t.string :direction
      t.references :count_variable, index: true
      t.references :transit_mode, index: true
      t.references :sector, index: true
      t.references :transit_agency, index: true
      t.integer :hour
      t.integer :in_station_id
      t.integer :out_station_id
      t.references :transit_route, index: true
      t.references :location, index: true
      t.float :count

      t.timestamps
    end
  end
end
