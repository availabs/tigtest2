class AddValueNameToView < ActiveRecord::Migration
  def change
    add_column :views, :value_name, :string
  end
end
