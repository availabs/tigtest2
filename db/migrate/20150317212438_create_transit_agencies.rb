class CreateTransitAgencies < ActiveRecord::Migration
  def change
    create_table :transit_agencies do |t|
      t.string :name
      t.string :contact

      t.timestamps
    end
  end
end
