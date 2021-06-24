class AddColumnToSpeedFact < ActiveRecord::Migration
  def change
    add_reference :speed_facts, :view, index: true
  end
end
