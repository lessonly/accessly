require "accessly/base"

module Accessly
  # Accessly::Query is the interface that hides the implementation
  # of the data layer. Ask Accessly::Query whether an actor
  # has permission on a record, ask it for a list of permitted records for the record
  # type, and ask it whether an actor has a general permission not
  # related to any certain record or record type.
  class Query < Base

    # Create an instance of Accessly::Query.
    # Lookups are cached in inherited object(s) to prevent redundant calls to the database.
    # Pass in a Hash or ActiveRecord::Base for actors if the actor(s)
    # inherit some permissions from other actors in the system. This may happen
    # when you have a user in one or more groups or organizations with their own
    # access control permissions.
    #
    # @param actors [Hash, ActiveRecord::Base] The actor(s) we're checking permission(s)
    #
    # @example
    #   # Create a new object with a single actor
    #   Accessly::Query.new(user)
    #   # Create a new object with multiple actors
    #   Accessly::Query.new(User => user.id, Group => [1,2], Organization => Organization.where(user_id: user.id).pluck(:id))
    def initialize(actors)
      super(actors)
    end

    # Check whether an actor has a given permission.
    # @return [Boolean]
    # @overload can?(action_id, namespace)
    #   Ask whether the actor has permission to perform action_id
    #   in the given namespace. Multiple actions can have the same id
    #   as long as their namespace is different. The namespace can be
    #   any String. We recommend using namespace to group a class of
    #   permissions, such as to group parts of a particular feature
    #   in your application.
    #
    #   @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
    #   @param namespace [String] The namespace of the given action_id.
    #   @return [Boolean] Returns true if actor has been granted the permission, false otherwise.
    #
    #   @example
    #     # Can the user perform the action with id 3 for posts?
    #     Accessly.can?(user, 3, "posts")
    #     # Can the user perform the action with id 5 for Posts?
    #     Accessly::Query.new(user).can?(5, Post)
    #     # Can the sets of actors perform the action with id 5 for Posts?
    #     Accessly::Query.new(User => user.id, Group => [1,2]).can?(5, Post)
    #     # Can the user on segment 1 perform the action with id 5 for Posts
    #     Accessly::Query.new(user).on_segment(1).can?(5, Post)
    #     # Can the sets of actors on segment 1 perform the action with id 5 for Posts
    #     Accessly::Query.new(User => user.id, Group => [1,2]).on_segment(1).can?(5, Post)
    #
    # @overload can?(action_id, object_type, object_id)
    #   Ask whether the actor has permission to perform action_id
    #   on a given record.
    #
    #   @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
    #   @param object_type [ActiveRecord::Base] The ActiveRecord model which we're checking for permission on.
    #   @param object_id [Integer] The id of the ActiveRecord object which we're checking for permission on.
    #   @return [Boolean] Returns true if actor has been granted the permission on the specified record, false otherwise.
    #
    #   @example
    #     # Can the user perform the action with id 5 for the Post with id 7?
    #     Accessly::Query.new(user).can?(5, Post, 7)
    #     # Can the sets of actors perform the action with id 5 for the Post with id 7?
    #     Accessly::Query.new(User => user.id, Group => [1,2]).can?(5, Post, 7)
    #     # Can the user on segment 1 perform the action with id 5 for the Post with id 7?
    #     Accessly::Query.new(user).on_segment(1).can?(5, Post, 7)
    #     # Can the sets of actors on segment 1 perform the action with id 5 for the Post with id 7?
    #     Accessly::Query.new(User => user.id, Group => [1,2]).on_segment(1).can?(5, Post, 7)
    def can?(action_id, object_type, object_id = nil)
      if object_id.nil?
        permitted_action_query.can?(action_id, object_type)
      else
        permitted_action_on_object_query.can?(action_id, object_type, object_id)
      end
    end

    def list(action_id, object_type)
    end

    private

    def permitted_action_query
      @_permitted_action_query ||= Accessly::PermittedActions::Query.new(@actors, @segment_id)
    end

    def permitted_action_on_object_query
      @_permitted_action_on_object_query ||= Accessly::PermittedActions::OnObjectQuery.new(@actors, @segment_id)
    end
  end
end
