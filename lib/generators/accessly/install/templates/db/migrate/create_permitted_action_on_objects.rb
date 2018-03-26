class CreatePermittedActionOnObjects < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :accessly_permitted_action_on_objects, force: true, id: :uuid do |t|
      t.column :segment_id, :integer, default: -1
      t.column :action, :integer, null: false
      t.column :actor_id, :integer, null: false
      t.column :actor_type, :string, null: false
      t.column :object_type, :string, null: false
      t.column :object_id, :integer, null: false
    end

    add_index(:accessly_permitted_action_on_objects, [:segment_id, :actor_type, :actor_id, :object_type, :object_id, :action], unique: true, name: "acessly_paoo_uniq_table_idx")
    add_index(:accessly_permitted_action_on_objects, [:segment_id, :object_type, :object_id, :action], name: "acessly_paoo_on_object_idx")
  end
end
