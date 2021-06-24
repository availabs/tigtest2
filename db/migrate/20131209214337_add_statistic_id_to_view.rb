class AddStatisticIdToView < ActiveRecord::Migration
  def change
    add_column :views, :statistic_id, :integer, references: :statistics
  end
end
