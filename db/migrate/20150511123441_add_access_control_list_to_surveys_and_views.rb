class AddAccessControlListToSurveysAndViews < ActiveRecord::Migration
  def change
    create_table :access_controls do |t|
      t.integer :source_id
      t.integer :view_id
      t.integer :agency_id
      t.integer :user_id
      t.string :role    
      t.boolean :show
      t.boolean :download
      t.boolean :comment

      t.timestamps
    end
  end
end
