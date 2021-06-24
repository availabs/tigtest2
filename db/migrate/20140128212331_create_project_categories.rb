class CreateProjectCategories < ActiveRecord::Migration
  def change
    create_table :project_categories do |t|
      t.string :name

      t.timestamps
    end
    add_index :project_categories, :name
  end
end
