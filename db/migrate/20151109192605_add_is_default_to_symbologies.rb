class AddIsDefaultToSymbologies < ActiveRecord::Migration
  def change
    add_column :symbologies, :is_default, :boolean
  end
end
