class AddOptionsToNumberFormatter < ActiveRecord::Migration
  def change
    add_column :number_formatters, :options, :string
  end
end
