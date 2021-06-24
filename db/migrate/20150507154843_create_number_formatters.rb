class CreateNumberFormatters < ActiveRecord::Migration
  def change
    create_table :number_formatters do |t|
      t.string :format_type, null: false
      t.string :format
      t.string :locale, default: 'us'

      t.timestamps
    end
  end
end
