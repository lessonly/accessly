require "accesscontrol/version"
require "accesscontrol/records"
require "accesscontrol/general"

module AccessControl
  module_function

  def self.table_name_prefix
    "access_control_"
  end

  def can?(actor, action_id, object_type, object_id = nil)
    if object_id.nil?
      General.can?(actor, action_id, object_type)
    else
      Records.can?(actor, action_id, object_type, object_id)
    end
  end

  def list(actor, action_id, object_type)
    Records.list(actor, action_id, object_type)
  end

  def grant(actor, action_id, object_type, object_id = nil)
  end

  def revoke(actor, action_id, object_type, object_id = nil)
  end

end
