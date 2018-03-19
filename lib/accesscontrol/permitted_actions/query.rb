require "accesscontrol/permitted_actions/base"

module AccessControl
  module PermittedActions
    class Query < Base

      def initialize(actors, segment_id)
        super(actors, segment_id)
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
              segment_id: @segment_id,
              action: action_id,
              object_type: String(object_type),
            ).exists?
        end
      end
    end
  end
end
