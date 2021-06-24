class AddLinkIdToLink < ActiveRecord::Migration
  def up
    add_column :links, :link_id, :integer, limit: 8
    change_column :links, :id, :integer, limit: 4
    change_column :link_speed_facts, :link_id, :integer, limit: 4
  end
  def down
    change_column :link_speed_facts, :link_id, :integer, limit: 8
    change_column :links, :id, :integer, limit: 8
    remove_column :links, :link_id, :integer, limit: 8
  end
end
