module Accessly
  module Policy
    class Base

      attr_reader :actor

      def initialize(actor)
        @actor = actor
      end

      def self.actions(actions)
        _actions.merge!(actions)
        actions.each do |action, action_id|
          _define_action_method(action, action_id)
        end
      end

      def self.actions_on_objects(actions_on_objects)
        _actions_on_objects.merge!(actions_on_objects)
        actions_on_objects.each do |action, action_id|
          _define_action_method(action, action_id)
        end
      end

      def self.namespace
        String(self)
      end

      def namespace
        self.class.namespace
      end

      def is_admin?
        false
      end

      def accessly_query
        @_accessly_query ||= Accessly::Query.new(actor)
      end

      private

      # Determines whether the caller is trying to call an action method
      # in the format `action_name?`. If so, this calls that method with
      # the given arguments.
      def method_missing(method_name, *args)
        action_method_name = _resolve_action_method_name(method_name)
        if action_method_name.nil?
          super
        else
          send(action_method_name, *args)
        end
      end

      # Parses an action name from a given method name of the format
      # `action_name?` and returns the action method name. If the
      # method name does not follow that format, this assumes the
      # caller is not calling an action method and returns nil.
      def _resolve_action_method_name(method_name)
        action_method_match = /\A(\w+)\?\z/.match(method_name)

        return nil if action_method_match.nil? || action_method_match[1].nil?

        action_name = action_method_match[1].to_sym
        if _action_defined?(action_name)
          _action_method_name(action_name)
        else
          nil
        end
      end

      # The implementation for action methods follow the naming format
      # `_resolve_action_name`. This is to allow child Policies to override
      # the action method and still be able to call `super` when they
      # need to call the base implementation of the action method.
      def self._action_method_name(action_name)
        "_resolve_#{action_name}"
      end

      def _action_method_name(action_name)
        self.class._action_method_name(action_name)
      end

      # Defines the action method on the Policy class for the given
      # action name.
      def self._define_action_method(action, action_id)
        unless method_defined?(_action_method_name(action))
          define_method(_action_method_name(action)) do |*args|
            _can_do_action?(action, action_id, args.first)
          end
        end
      end

      # Determines whether the caller is calling an object action
      # method or a non-object action method and calls the appropriate
      # implementation.
      def _can_do_action?(action, action_id, object)
        if object.nil?
          _can_do_action_without_object?(action, action_id)
        else
          _can_do_action_with_object?(action, action_id, object)
        end
      end

      # Determines whether the actor has permission to do the action
      # outside of an object context. If the actor is an admin, then
      # this returns true without checking.
      #
      # @return [Boolean]
      def _can_do_action_without_object?(action, action_id)
        if _actions[action].nil?
          raise ArgumentError.new("#{action} is not defined as a general action for #{self.class.name}")
        elsif is_admin?
          true
        else
          accessly_query.can?(action_id, namespace)
        end
      end

      # Determines whether the actor has permission to do the action
      # on an object. If the actor is an admin, then this returns
      # true without checking.
      #
      # @return [Boolean]
      def _can_do_action_with_object?(action, action_id, object)
        object_id = object.respond_to?(:id) ? object.id : object

        if _actions_on_objects[action].nil?
          raise ArgumentError.new("#{action} is not defined as an action-on-object for #{self.class.name}")
        elsif is_admin?
          true
        else
          accessly_query.can?(action_id, namespace, object_id)
        end
      end

      def self._action_defined?(action_name)
        _actions.include?(action_name) || _actions_on_objects.include?(action_name)
      end

      def _action_defined?(action_name)
        self.class._action_defined?(action_name)
      end

      def self._actions
        @@_actions ||= {}
      end

      def _actions
        self.class._actions
      end

      def self._actions_on_objects
        @@_actions_on_objects ||= {}
      end

      def _actions_on_objects
        self.class._actions_on_objects
      end
    end
  end
end
