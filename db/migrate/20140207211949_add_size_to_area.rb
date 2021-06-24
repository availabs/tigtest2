class AddSizeToArea < ActiveRecord::Migration
  def change
    add_column :areas, :size, :float
  end
end
