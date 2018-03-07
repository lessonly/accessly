require "accesscontrol/version"
require "accesscontrol/models/permitted_action"

module AccessControl
  module_function

  def self.table_name_prefix
    "access_control_"
  end

  def can?(actor, action_id, object_type, object_id = nil)
    if object_id.nil?
      PermittedAction.where(
        actor: actor,
        action: action_id,
        object_type: String(object_type),
      ).exists?
    else
      PermittedActionOnObject.where(
        actor: actor,
        action: action_id,
        object_type: String(object_type),
        object_id: object_id
      ).exists?
    end
  end

  def list(actor, action_id, object_type)
  end

  def grant(actor, action_id, object_type, object_id = nil)
  end

  def revoke(actor, action_id, object_type, object_id = nil)
  end

end
