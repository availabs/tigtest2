class CreateSpeedFactTmcVersionMappings < ActiveRecord::Migration
  def change
    create_table :speed_fact_tmc_version_mappings do |t|
      t.integer :data_year
      t.integer :tmc_year

      t.timestamps
    end
  end
end
