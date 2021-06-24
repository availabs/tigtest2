class CreateDemographicFacts < ActiveRecord::Migration
  def change
    create_table :demographic_facts do |t|
      t.references :view
      t.references :area
      t.integer :year
      t.references :statistic
      t.float :value

      t.timestamps
    end
    add_index :demographic_facts, :view_id
    add_index :demographic_facts, :area_id
    add_index :demographic_facts, :statistic_id
  end
end
