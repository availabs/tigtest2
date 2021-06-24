class AddViewRefToSymbology < ActiveRecord::Migration
  def change
    add_reference :symbologies, :view, index: true
  end
end
