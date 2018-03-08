module AccessControl
  module General
    module_function

    def can?(actor, action_id, object_type)
      PermittedAction.where(
        actor: actor,
        action: action_id,
        object_type: String(object_type),
      ).exists?
    end
  end
end
