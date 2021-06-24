class AddDeletedAtToViews < ActiveRecord::Migration
  def change
    add_column :views, :deleted_at, :datetime
  end
end
