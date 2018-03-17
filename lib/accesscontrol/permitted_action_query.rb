require "accesscontrol/query_builder"

module AccessControl
  class PermittedActionQuery

    def initialize(actors)
      @actors = actors
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
    #   AccessControl::Query.new(actor).can?(3, Post)
    def can?(action_id, object_type)
      find_or_set_value(action_id, object_type) do
        AccessControl::QueryBuilder.with_actors(PermittedAction, @actors)
          .where(
            action: action_id,
            object_type: String(object_type),
          ).exists?
      end
    end

    # Allow permission on a general action in the given namespace represented by object_type.
    # A grant is universally unique and is enforced at the database level.
    #
    # @param action_id [Integer] The action to grant for the object
    # @param object_type [String] The namespace of the given action_id.
    # @raise [AccessControl::CouldNotGrantError] if the operation does not succeed
    # @return [nil] Returns nil if successful
    #
    # @example
    #   # Allow the user access to posts
    #   AccessControl::Query.new(user).grant(3, "posts")
    def grant(action_id, object_type)
      PermittedAction.create!(
        id: SecureRandom.uuid,
        actor: @actor,
        action: action_id,
        object_type: String(object_type)
      )
      nil
    rescue ActiveRecord::RecordNotUnique
      nil
    rescue => e
      raise AccessControl::CouldNotGrantError.new("Could not grant action #{action_id} on object #{object_type} for actor #{@actor} because #{e}")
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
