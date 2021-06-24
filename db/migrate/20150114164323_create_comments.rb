class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.references :user, index: true
      t.string :subject
      t.text :text
      t.references :source, index: true
      t.references :view, index: true
      t.integer :app

      t.timestamps
    end
  end
end
