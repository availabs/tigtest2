class AddContributorViewTable < ActiveRecord::Migration
  def change
    create_table :contributors_views, id: false do |t|
      t.references :user, index: true
      t.references :view, index: true
    end
  end
end
