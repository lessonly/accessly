ActiveRecord::Schema.define(version: 1) do
  create_table :users, force: true do |t|
  end

  create_table :posts, force: true do |t|
  end

  create_table :access_control_permitted_actions, force: true, id: :uuid do |t|
    t.column :segment_id, :integer, default: -1
    t.column :action, :integer
    t.column :actor_id, :integer
    t.column :actor_type, :string
    t.column :object_type, :string
  end

  create_table :access_control_permitted_action_on_objects, force: true, id: :uuid do |t|
    t.column :segment_id, :integer, default: -1
    t.column :action, :integer
    t.column :actor_id, :integer
    t.column :actor_type, :string
    t.column :object_type, :string
    t.column :object_id, :integer
  end

  add_index(:access_control_permitted_actions, [:segment_id, :action, :actor_id, :actor_type, :object_type], unique: true, name: "acpm_acpa_uniq_table_idx")
  add_index(:access_control_permitted_action_on_objects, [:segment_id, :action, :actor_id, :actor_type, :object_type, :object_id], unique: true, name: "acpm_acpaoo_uniq_table_idx")

end
