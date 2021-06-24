class AddNumberFormatterRefToSymbologies < ActiveRecord::Migration
  def change
    add_reference :symbologies, :number_formatter, index: true
  end
end
