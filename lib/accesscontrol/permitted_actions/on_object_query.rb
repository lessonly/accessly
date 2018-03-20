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

      # Returns an ActiveRecord::Relation of object_type containing the
      # records on which the actor has permission to perform action_id.
      #
      # @param action_id [Integer] The action we're checking on the actor for the object.
      # @param object_type [ActiveRecord::Base] The ActiveRecord model to be loaded.
      # @raise [AccessControl::ListError] if the object_type is not of type ActiveRecord::Base
      # @return [ActiveRecord::Relation]
      #
      # @example
      #   # Give me the list of Posts on which the user has permission to perform action_id 3
      #   AccessControl::Query.new(user).list(3, Post)
      #   # Give me the list of Posts on which the user has permission to perform action_id 3 on segment 1
      #   AccessControl::Query.new(user).on_segment(1).list(3, Post)
      #   # Give me the list of Posts on which the user and its groups has permission to perform action_id 3
      #   AccessControl::Query.new(User => user.id, Group => [1,2]).list(3, Post)
      #   # Give me the list of Posts on which the user and its groups has permission to perform action_id 3 on segment 1
      #   AccessControl::Query.new(User => user.id, Group => [1,2]).on_segment(1).list(3, Post)

      def list(action_id, object_type)
        raise AccessControl::ListError.new("object_type must be of ActiveRecord::Base") unless object_type.class === ActiveRecord::Base

        object_type.where(id:
          AccessControl::QueryBuilder.with_actors(PermittedActionOnObject, @actors)
            .where(
              segment_id: @segment_id,
              action: action_id,
              object_type: String(object_type),
            ).select(:object_id)
        )
      end
    end
  end
end
