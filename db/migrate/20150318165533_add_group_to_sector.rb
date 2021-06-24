class AddGroupToSector < ActiveRecord::Migration
  def change
    add_column :sectors, :group, :string
  end
end
