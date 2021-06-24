class AddGeometryBaseYearToViews < ActiveRecord::Migration
  def change
    add_column :views, :geometry_base_year, :integer
  end
end
