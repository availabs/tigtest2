class AddContributorSourceTable < ActiveRecord::Migration
  def change
    create_table :contributors_sources, id: false do |t|
      t.references :user, index: true
      t.references :source, index: true
    end
  end
end
