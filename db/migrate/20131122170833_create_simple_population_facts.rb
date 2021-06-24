class CreateSimplePopulationFacts < ActiveRecord::Migration
  def change
    create_table :simple_population_facts do |t|
      t.string :area_name
      t.float :population

      t.timestamps
    end
  end
end
