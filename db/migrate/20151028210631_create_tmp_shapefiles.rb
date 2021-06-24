class CreateTmpShapefiles < ActiveRecord::Migration
  def change
    create_table :tmp_shapefiles do |t|
      t.binary :data

      t.timestamps
    end
  end
end
