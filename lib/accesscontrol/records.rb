module AccessControl
  module Records
    module_function

    def can?(actor, action_id, object_type, object_id)
      PermittedActionOnObject.where(
        actor: actor,
        action: action_id,
        object_type: String(object_type),
        object_id: object_id
      ).exists?
    end

    def list(actor, action_id, object_type)
      action_id = Integer(action_id)

      object_type.where(id: 
        PermittedActionOnObject.where(
          actor: actor,
          action: action_id,
          object_type: String(object_type)
        ).select(:object_id)
      )
    end
  end
end
