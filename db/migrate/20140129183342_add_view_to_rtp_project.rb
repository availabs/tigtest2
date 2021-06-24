class AddViewToRtpProject < ActiveRecord::Migration
  def change
    add_column :rtp_projects, :view_id, :integer
    add_index :rtp_projects, :view_id
  end
end
