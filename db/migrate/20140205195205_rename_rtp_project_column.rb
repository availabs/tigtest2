class RenameRtpProjectColumn < ActiveRecord::Migration
  def change
    rename_column :rtp_projects, :rtp_id_201, :rtp_id
  end
end
