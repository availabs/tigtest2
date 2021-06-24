class RemoveColumnsFromNumberFormatter < ActiveRecord::Migration
  def change
    remove_column :number_formatters, :format 
    remove_column :number_formatters, :locale
  end
end
