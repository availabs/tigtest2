class CreateJoinTableAreaArea < ActiveRecord::Migration
  def change
    create_table :area_enclosures, force: true, id: false do |t|
      t.integer :enclosing_area_id, null: false
      t.integer :enclosed_area_id, null: false
      t.index [:enclosing_area_id, :enclosed_area_id], unique: true
      t.index [:enclosed_area_id, :enclosing_area_id], unique: true
    end
  end
end
