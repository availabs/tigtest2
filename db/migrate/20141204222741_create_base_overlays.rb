class CreateBaseOverlays < ActiveRecord::Migration
  def change
    create_table :base_overlays do |t|
      t.string :type
      t.text :properties

      t.timestamps
    end
  end
end
