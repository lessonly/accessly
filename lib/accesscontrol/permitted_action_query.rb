module AccessControl
  class PermittedActionQuery

    def initialize(actor)
      @actor = actor
    end

    # Ask whether the actor has permission to perform action_id
    # in the given namespace. Multiple actions can have the same id
    # as long as their namespace is different. The namespace can be
    # any String. We recommend using namespace to group a class of
    # permissions, such as to group parts of a particular feature
    # in your application.
    #
    # Lookups are cached in the object to prevent redundant database calls.
    #
    # @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
    # @param namespace [String] The namespace of the given action_id.
    # @return [Boolean] Returns true if actor has been granted the permission, false otherwise.
    #
    # @example
    #   # Can the user perform the action with id 3 for posts?
    #   AccessControl::General.can?(user, 3, "posts")
    def can?(action_id, object_type)
      find_or_set_value(@actor.class.name, @actor.id, action_id, object_type) do
        PermittedAction.where(
          actor: @actor,
          action: action_id,
          object_type: String(object_type),
        ).exists?
      end
    end

    private

    def past_lookups
      @_past_lookups ||= {}
    end

    def find_or_set_value(*keys, &query)
      found_value = past_lookups.dig(*keys)

      if found_value.nil?
        found_value =  query.call
        set_value(*keys, value: found_value)
      end

      found_value
    end

    def set_value(*keys, value:)
      lookup = past_lookups
      keys[0..-2].each do |key|
        lookup[key] ||= {}
        lookup = lookup[key]
      end

      lookup[keys[-1]] = value
    end
  end
end
