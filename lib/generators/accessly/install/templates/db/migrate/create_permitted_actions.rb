class CreatePermittedActions < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :accessly_permitted_actions, force: true, id: :uuid do |t|
      t.column :segment_id, :integer, default: -1
      t.column :action, :integer, null: false
      t.column :actor_id, :integer, null: false
      t.column :actor_type, :string, null: false
      t.column :object_type, :string, null: false
    end

    add_index(:accessly_permitted_actions, [:segment_id, :action, :actor_id, :actor_type, :object_type], unique: true, name: "acessly_pa_uniq_table_idx")
  end
end
