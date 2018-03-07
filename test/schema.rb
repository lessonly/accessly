ActiveRecord::Schema.define(version: 1) do
  create_table :users, force: true do |t|
  end

  create_table :access_control_permitted_actions, force: true, id: :uuid do |t|
    t.column :segment_id, :integer
    t.column :action, :integer
    t.column :actor_id, :integer
    t.column :actor_type, :string, limit: 50
    t.column :object_name, :string, limit: 50
  end

  create_table :access_control_permitted_actions_on_object, force: true do |t|
  end
end
