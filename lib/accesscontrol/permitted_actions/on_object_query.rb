
module AccessControl
  module PermittedActions
    class OnObjectQuery < Base

      def initialize(actors, segment_id)
        super(actors, segment_id)
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
      #   # Can the user perform the action with id 5 for the Post with id 7?
      #   AccessControl::Query.new(user).can?(5, Post, 7)
      #   # Can the user perform the action with id 5 for the Post with id 7 on segment 1?
      #   AccessControl::Query.new(user).on_segment(1).can?(5, Post, 7)
      def can?(action_id, object_type, object_id)
        find_or_set_value(:can, action_id, object_type) do
          AccessControl::QueryBuilder.with_actors(PermittedActionOnObject, @actors)
            .where(
              segment_id: @segment_id,
              action: action_id,
              object_type: String(object_type),
              object_id: object_id
            ).exists?
        end
      end
    end
  end
end
