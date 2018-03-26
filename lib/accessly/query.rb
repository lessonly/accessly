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
    # @overload can?(action_id, namespace, namespace_id)
    #   Ask whether the actor has permission to perform action_id
    #   on a given record.
    #
    #   @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
    #   @param namespace [Class] The namespace which we're checking for permissions.
    #   @param namespace_id [Integer] The id of the namespace object which we're checking for permission on.
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
    def can?(action_id, namespace, namespace_id = nil)
      if namespace_id.nil?
        permitted_action_query.can?(action_id, namespace)
      else
        permitted_action_on_object_query.can?(action_id, namespace, namespace_id)
      end
    end

    # Returns an ActiveRecord::Relation of ids in the namespace for
    # which the actor has permission to perform action_id.
    #
    # @param action_id [Integer] The action we're checking on the actor in the namespace.
    # @param namespace [String] The namespace to check actor permissions.
    # @return [ActiveRecord::Relation]
    #
    # @example
    #   # Give me the list of Post ids on which the user has permission to perform action_id 3
    #   Accessly::Query.new(user).list(3, Post)
    #   # Give me the list of Post ids on which the user has permission to perform action_id 3 on segment 1
    #   Accessly::Query.new(user).on_segment(1).list(3, Post)
    #   # Give me the list of Post ids on which the user and its groups has permission to perform action_id 3
    #   Accessly::Query.new(User => user.id, Group => [1,2]).list(3, Post)
    #   # Give me the list of Post ids on which the user and its groups has permission to perform action_id 3 on segment 1
    #   Accessly::Query.new(User => user.id, Group => [1,2]).on_segment(1).list(3, Post)
    def list(action_id, namespace)
      permitted_action_on_object_query.list(action_id, namespace)
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
