class RolifyCreateActions < ActiveRecord::Migration
  def change
    create_table(:actions) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:views_actions, :id => false) do |t|
      t.references :view
      t.references :action
    end

    add_index(:actions, :name)
    add_index(:actions, [ :name, :resource_type, :resource_id ])
    add_index(:views_actions, [ :view_id, :action_id ])
  end
end
