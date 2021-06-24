class AddPublishedToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :published, :boolean, default: false
    drop_table :viewers_study_areas if ActiveRecord::Base.connection.tables.include?('viewers_study_areas')
    create_table :viewers_study_areas, id: false do |t|
      t.references :user, index: true
      t.references :study_area, index: true
    end
  end
end
