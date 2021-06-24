class AddYearToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :year, :integer
  end
end
