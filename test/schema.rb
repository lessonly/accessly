ActiveRecord::Schema.define(version: 1) do
  create_table :users, force: true do |t|
  end

  create_table :posts, force: true do |t|
  end

  create_table :groups, force: true do |t|
  end

  create_table :accessly_permitted_actions, force: true, id: :uuid do |t|
    t.column :segment_id, :integer, default: -1
    t.column :action, :integer, null: false
    t.column :actor_id, :integer, null: false
    t.column :actor_type, :string, null: false
    t.column :object_type, :string, null: false
  end

  create_table :accessly_permitted_action_on_objects, force: true, id: :uuid do |t|
    t.column :segment_id, :integer, default: -1
    t.column :action, :integer, null: false
    t.column :actor_id, :integer, null: false
    t.column :actor_type, :string, null: false
    t.column :object_type, :string, null: false
    t.column :object_id, :integer, null: false
  end

  add_index(:accessly_permitted_actions, [:segment_id, :action, :actor_id, :actor_type, :object_type], unique: true, name: "accessly_pa_uniq_table_idx")
  add_index(:accessly_permitted_action_on_objects, [:segment_id, :action, :actor_id, :actor_type, :object_type, :object_id], unique: true, name: "accessly_paoo_uniq_table_idx")

end
