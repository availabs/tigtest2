class CreateSimpleYearPopFacts < ActiveRecord::Migration
  def change
    create_table :simple_year_pop_facts do |t|
      t.string :area_name
      t.float :pop_2000
      t.float :pop_2005
      t.float :pop_2010
      t.float :pop_2015
      t.float :pop_2020
      t.float :pop_2025
      t.float :pop_2030
      t.float :pop_2035
      t.float :pop_2040

      t.timestamps
    end
  end
end
