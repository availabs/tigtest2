class CreateTransitRoutes < ActiveRecord::Migration
  def change
    create_table :transit_routes do |t|
      t.string :name
      t.references :transit_agency, index: true

      t.timestamps
    end
  end
end
