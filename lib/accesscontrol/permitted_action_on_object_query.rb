require "accesscontrol/query_builder"

module AccessControl

  # Permission checks directly related to specific ActiveRecord records happen here.
  class PermittedActionOnObjectQuery

    def initialize(actors)
      @actors = actors
    end

    # Ask whether the actor has permission to perform action_id
    # on a given record.
    #
    # Lookups are cached in the object to prevent redundant database calls.
    #
    # @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
    # @param object_type [ActiveRecord::Base] The ActiveRecord model which we're checking for permission on.
    # @param object_id [Integer] The id of the ActiveRecord object which we're checking for permission on.
    # @return [Boolean] Returns true if actor has been granted the permission on the specified record, false otherwise.
    #
    # @example
    #   # Can the actor perform the action with id 5 for the Post with id 7?
    #   AccessControl::Query.new(actor).can?(5, Post, 7)
    def can?(action_id, object_type, object_id)
      find_or_set_value(:can, action_id, object_type) do
        AccessControl::QueryBuilder.with_actors(PermittedActionOnObject, @actors)
          .where(
            action: action_id,
            object_type: String(object_type),
            object_id: object_id
          ).exists?
      end
    end

    # Allow permission on an ActiveRecord object.
    # A grant is universally unique and is enforced at the database level.
    #
    # @param action_id [Integer] The action to grant for the object
    # @param object_type [ActiveRecord::Base] The ActiveRecord model that receives a permission grant.
    # @param object_id [Integer] The id of the ActiveRecord object which receives a permission grant
    # @raise [AccessControl::CouldNotGrantError] if the operation does not succeed
    # @return [nil] Returns nil if successful
    #
    # @example
    #   # Allow the user access to Post 7
    #   AccessControl::Query.new(user).grant(3, Post, 7)
    def grant(action_id, object_type, object_id)
      PermittedActionOnObject.create!(
        id: SecureRandom.uuid,
        actor_type: @actors.keys.first,
        actor_id: @actors.values.first,
        action: action_id,
        object_type: String(object_type),
        object_id: object_id
      )
      nil
    rescue ActiveRecord::RecordNotUnique
      nil
    rescue => e
      raise AccessControl::CouldNotGrantError.new("Could not grant action #{action_id} on object #{object_type} with id #{object_id} for actor #{@actor} because #{e}")
    end

    def list(action_id, object_type)
    end

    private

    def past_lookups
      @_past_lookups ||= {}
    end

    def find_or_set_value(*keys, &query)
      found_value = past_lookups.dig(*keys)

      if found_value.nil?
        found_value = query.call
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
