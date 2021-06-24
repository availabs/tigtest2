class AddRecentActivityLimitToUser < ActiveRecord::Migration
  def change
    add_column :users, :recent_activity_dashboard_limit, :integer, default: 3
    add_column :users, :recent_activity_expanded_limit, :integer, default: 10
  end
end
