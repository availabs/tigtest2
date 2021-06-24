class AddDefaultDataModelToSource < ActiveRecord::Migration
  def change
    add_column :sources, :default_data_model, :text
  end
end
