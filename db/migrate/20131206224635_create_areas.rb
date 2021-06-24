class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.string :name
      t.string :type
      t.references :enclosing_area

      t.timestamps
    end
    add_index :areas, :enclosing_area_id
  end
end
