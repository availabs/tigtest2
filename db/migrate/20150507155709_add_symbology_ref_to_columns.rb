class AddSymbologyRefToColumns < ActiveRecord::Migration
  def change
    add_reference :columns, :symbology, index: true
  end
end
