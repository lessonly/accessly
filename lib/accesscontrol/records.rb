module AccessControl

  # Permission checks directly related to specific ActiveRecord records happen here.
  module Records
    module_function

    # Ask whether the actor has permission to perform action_id
    # on a given record.
    #
    # @param actor [ActiveRecord::Base] The actor we're checking for permission on.
    # @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
    # @param object_type [ActiveRecord::Base] The ActiveRecord model which we're checking for permission on.
    # @param object_id [Integer] The id of the ActiveRecord object which we're checking for permission on.
    # @return [Boolean] Returns true if actor has been granted the permission on the specified record, false otherwise.
    #
    # @example
    #   # Can the user perform the action with id 5 for the Post with id 7?
    #   AccessControl::Records.can?(user, 5, Post, 7)
    def can?(actor, action_id, object_type, object_id)
      PermittedActionOnObject.where(
        actor: actor,
        action: action_id,
        object_type: String(object_type),
        object_id: object_id
      ).exists?
    end

    # Returns an ActiveRecord::Relation of object_type containing the
    # records on which the actor has permission to perform action_id.
    #
    # @param actor [ActiveRecord::Base] The actor we're loading records for.
    # @param action_id [Integer] The action we're checking whether the actor has.
    # @param object_type [ActiveRecord::Base] The ActiveRecord model to be loaded.
    # @return [ActiveRecord::Relation]
    #
    # @example
    #   # Give me the list of Posts on which the user has permission to perform action_id 3
    #   AccessControl.list(user, 3, Post)
    # @example
    #   # You can chain ActiveRecord query methods to further filter the results
    #   # Give me the list of Posts on which the user has permission to perform action_id 3, and which have the title "Untitled", but limit to 5 results
    #   AccessControl::Records.list(user, 3, Post).where(title: "Untitled").limit(5)
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
