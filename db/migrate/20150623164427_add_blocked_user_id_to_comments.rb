class AddBlockedUserIdToComments < ActiveRecord::Migration
  def change
    add_column :comments, :blocked_by_id, :integer
  end
end
