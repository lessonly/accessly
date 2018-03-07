require "accesscontrol/version"
require "accesscontrol/models/permitted_action"

module AccessControl
  module_function

  def can?(actor, action_id, object_name, object_id = nil)
    PermittedAction.where(
      actor: actor,
      action: action_id,
      object_name: object_name
    ).exists?
  end

  def list(actor, action_id, object_name)
  end

  def grant(actor, action_id, object_name, object_id = nil)
  end

  def revoke(actor, action_id, object_name, object_id = nil)
  end
end
