class AddSourceUploadFields < ActiveRecord::Migration
  def change
    add_column :uploads, :to_year, :integer
    add_column :uploads, :data_level, :string
  end
end
