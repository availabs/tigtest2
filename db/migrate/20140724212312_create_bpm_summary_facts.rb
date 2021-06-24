class CreateBpmSummaryFacts < ActiveRecord::Migration
  def change
    create_table :bpm_summary_facts do |t|
      t.references :view
      t.references :area
      t.integer :year
      t.string :orig_dest
      t.string :purpose
      t.string :mode
      t.integer :count

      t.timestamps
    end
    add_index :bpm_summary_facts, :view_id
    add_index :bpm_summary_facts, :area_id
    add_index :bpm_summary_facts, :year
    add_index :bpm_summary_facts, :orig_dest
    add_index :bpm_summary_facts, :purpose
    add_index :bpm_summary_facts, :mode
  end
end
