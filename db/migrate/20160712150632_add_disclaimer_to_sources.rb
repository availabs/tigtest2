class AddDisclaimerToSources < ActiveRecord::Migration
  def change
    add_column :sources, :disclaimer, :text
  end
end
