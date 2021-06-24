class AddDataModelToView < ActiveRecord::Migration
  def change
    add_column :views, :data_model, :text
  end
end
