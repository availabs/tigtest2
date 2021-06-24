class AddLibrarianTables < ActiveRecord::Migration
  def change
    create_table :librarians_views, id: false do |t|
      t.references :user, index: true
      t.references :view, index: true
    end
    create_table :librarians_sources, id: false do |t|
      t.references :user, index: true
      t.references :source, index: true
    end
  end
end
