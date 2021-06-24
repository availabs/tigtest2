class AddYearToTmcs < ActiveRecord::Migration
  def change
    add_column :tmcs, :year, :integer
  end
end
