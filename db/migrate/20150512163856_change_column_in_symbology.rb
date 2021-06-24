class ChangeColumnInSymbology < ActiveRecord::Migration
  def change
    change_column :symbologies, :default_column_index, :string
  end
end
