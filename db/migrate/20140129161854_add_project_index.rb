class AddProjectIndex < ActiveRecord::Migration
  def change
    add_index :rtp_projects, :rtp_id_201
  end
end
