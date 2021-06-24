class AddFipsCodeToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :fips_code, :integer, limit: 8
    add_index :areas, :fips_code
  end
end
