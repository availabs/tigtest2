class ChangeLinkSpeedFactLinkIdColumn < ActiveRecord::Migration
  def change
    change_column :link_speed_facts, :link_id, :integer, limit: 8
  end
end
