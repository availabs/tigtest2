class CreateComparativeFacts < ActiveRecord::Migration
  def change
    create_table :comparative_facts do |t|
      t.references :view, index: true
      t.references :area, index: true
      t.references :statistic, index: true
      t.references :base_statistic, index: true
      t.float :value
      t.float :base_value

      t.timestamps
    end
  end
end
