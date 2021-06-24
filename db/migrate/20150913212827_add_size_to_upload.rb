class AddSizeToUpload < ActiveRecord::Migration
  def change
    add_column :uploads, :size_in_bytes, :integer
  end
end
