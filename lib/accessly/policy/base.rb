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
          _define_action_methods(action, action_id)
        end
      end

      def self.actions_on_objects(actions_on_objects)
        _actions_on_objects.merge!(actions_on_objects)
        actions_on_objects.each do |action, action_id|
          _define_action_methods(action, action_id)
        end
      end

      def self.namespace
        String(self)
      end

      def namespace
        self.class.namespace
      end

      def self.model_scope
        raise ArgumentError.new("#model_scope is not defined on #{self.name}.")
      end

      def model_scope
        self.class.model_scope
      end

      # Specifies all the actors used in permission lookups.
      # Override this method in child policy classes to specify
      # other actors that the actor given in the initializer may
      # inherit permissions from.
      def actors
        actor
      end

      def unrestricted?
        false
      end

      def segment_id
        nil
      end

      def can?(action, object = nil)
        if object.nil?
          send("#{action}?")
        else
          send("#{action}?", object)
        end
      end

      def list(action)
        send(action)
      end

      def grant(action, object = nil)
        object_id = _get_object_id(object)
        action_id = _get_action_id(action, object_id)
        grant_object.grant!(action_id, namespace, object_id)
      end

      def revoke(action, object = nil)
        object_id = _get_object_id(object)
        action_id = _get_action_id(action, object_id)
        revoke_object.revoke!(action_id, namespace, object_id)
      end

      def accessly_query
        @_accessly_query ||= begin
          query = Accessly::Query.new(actors)
          query.on_segment(segment_id) unless segment_id.nil?
          query
        end
      end

      def grant_object
        grant_object = Accessly::Permission::Grant.new(actor)
        grant_object.on_segment(segment_id) unless segment_id.nil?

        grant_object
      end

      def revoke_object
        revoke_object = Accessly::Permission::Revoke.new(actor)
        revoke_object.on_segment(segment_id) unless segment_id.nil?

        revoke_object
      end

      private

      def _get_action_id(action, object_id = nil)
        if object_id.nil?
          _get_general_action_id!(action)
        else
          _get_action_on_object_id!(action)
        end
      end

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
      # `action_name?` or `action_name and returns the action method
      # or the list method name. If the method name does not follow
      # one of those formats, this assumes the caller is not calling
      # an action or list method and returns nil.
      def _resolve_action_method_name(method_name)
        action_method_match = /\A(\w+)(\??)\z/.match(method_name)

        return nil if action_method_match.nil? || action_method_match[1].nil?

        action_name = action_method_match[1].to_sym
        is_predicate = action_method_match[2] == "?"

        if !_action_defined?(action_name)
          nil
        elsif is_predicate
          _action_method_name(action_name)
        else
          _action_list_method_name(action_name)
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

      # The implementation for list methods follow the naming format
      # `_list_action_name`. This is to allow child Policies to override
      # the list method and still be able to call `super` when they
      # need to call the base implementation of the lsit method.
      def self._action_list_method_name(action_name)
        "_list_#{action_name}"
      end

      def _action_list_method_name(action_name)
        self.class._action_list_method_name(action_name)
      end

      # Defines the action method on the Policy class for the given
      # action name.
      def self._define_action_methods(action, action_id)
        unless method_defined?(_action_method_name(action))
          define_method(_action_method_name(action)) do |*args|
            _can_do_action?(action, action_id, args.first)
          end
        end

        unless method_defined?(_action_list_method_name(action))
          define_method(_action_list_method_name(action)) do |*args|
            _list_for_action(action, action_id)
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
      # outside of an object context. If the actor should have unrestricted
      # access, then this returns true without checking.
      #
      # @return [Boolean]
      def _can_do_action_without_object?(action, action_id)
        if _actions[action].nil?
          _invalid_general_action!(action)
        elsif unrestricted?
          true
        else
          accessly_query.can?(action_id, namespace)
        end
      end

      # Determines whether the actor has permission to do the action
      # on an object. If the actor should have unrestricted access,
      # then this returns true without checking.
      #
      # @return [Boolean]
      def _can_do_action_with_object?(action, action_id, object)
        object_id = _get_object_id(object)

        if _actions_on_objects[action].nil?
          _invalid_action_on_object!(action)
        elsif unrestricted?
          true
        else
          accessly_query.can?(action_id, namespace, object_id)
        end
      end

      def _list_for_action(action, action_id)
        if _actions_on_objects[action].nil?
          _invalid_action_on_object!(action)
        elsif unrestricted?
          model_scope
        else
          model_scope.where(id: accessly_query.list(action_id, namespace))
        end
      end

      def _get_general_action_id!(action)
        _actions[action] || _invalid_general_action!(action)
      end

      def _get_action_on_object_id!(action)
        _actions_on_objects[action] || _invalid_action_on_object!(action)
      end

      def _invalid_general_action!(action)
        raise ArgumentError.new("#{action} is not defined as a general action for #{self.class.name}")
      end

      def _invalid_action_on_object!(action)
        raise ArgumentError.new("#{action} is not defined as an action-on-object for #{self.class.name}")
      end

      def _get_object_id(object)
        object.respond_to?(:id) ? object.id : object
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
