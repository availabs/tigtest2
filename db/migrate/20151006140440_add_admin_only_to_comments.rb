class AddAdminOnlyToComments < ActiveRecord::Migration
  def change
    add_column :comments, :admin_only, :boolean, default: false
  end
end
