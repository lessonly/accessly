module Accessly
  module Policy
    class Base
      # Module that will hold our meta-programmed action methods just above
      # the policy class in the inheritance hierarchy; allowing for them to
      # be overridden in the policy.
      ACTIONS_MODULE = :Actions

      attr_reader :actor

      def initialize(actor)
        @actor = actor
      end

      # Meta-programs action methods from actions supplied.
      # Used in policies as a DSL to declare actions.
      #
      # This defines the actions on the `actions_module` so that they are
      # positioned higher in the inheritance tree than methods defined on the
      # class itself. This will allow us to define methods that override these
      # base methods and call `super`.
      #
      # @param actions [Hash] the actions to define on the policy
      #
      # @example Define Actions
      #
      #   # This example causes the following methods to be defined:
      #   # some_action? : Returns true if the actor has the some_action
      #   #   permission, false otherwise
      #   # flip_the_flop? : Returns true if the actor has the flip_the_flop
      #   #   permission, false otherwise
      #   # create? : Returns true if the actor has the create permission, false
      #   #   otherwise
      #   actions(
      #     some_action: 1,
      #     flip_the_flop: 2,
      #     create: 3
      #   )
      #
      # @return [Hash] actions
      def self.actions(actions)
        _actions.merge!(actions)
        actions.each do |action, action_id|
          actions_module.module_eval do
            define_method(:"#{action}?") do |*args|
              _can_do_action?(action, action_id, args.first)
            end
          end
        end
      end

      # Meta-programs action_on_objects methods from the actions supplied.
      # Used in policies as a DSL to declare actions on objects.
      # It is different from actions in that it will also define a method
      # for listing all objects authorized with this action for the given
      # actor and that these actions will always be associated not only with
      # an actor, but with an object of the action.
      #
      # @param actions_on_objects [Hash] the actions on objects to define
      # on the policy
      #
      # @example Define Actions On Objects
      #
      #   # This example causes the following methods to be defined:
      #   # edit : Returns an ActiveRecord::Relation of the objects on which
      #   #   the actor has the edit permission
      #   # edit?(object) : Returns true if the actor has the edit permission
      #   #   on the given object, false otherwise
      #   # show : Returns an ActiveRecord::Relation of the objects on which
      #   #   the actor has the show permission
      #   # show?(object) : Returns true if the actor has the show permission
      #   #   on the given object, false otherwise
      #   actions_on_objects(
      #     edit: 1,
      #     show: 2
      #   )
      #
      # @return [Hash] actions_on_objects
      def self.actions_on_objects(actions_on_objects)
        _actions_on_objects.merge!(actions_on_objects)
        actions_on_objects.each do |action, action_id|
          actions_module.module_eval do
            define_method(:"#{action}?") do |*args|
              _can_do_action?(action, action_id, args.first)
            end

            define_method(action) do |*args|
              _list_for_action(action, action_id)
            end
          end
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

      def grant!(action, object = nil)
        object_id = _get_object_id(object)
        action_id = _get_action_id(action, object_id)
        grant_object.grant!(action_id, namespace, object_id)
      end

      def revoke!(action, object = nil)
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

      # Accessor for the actions module that will hold our meta-programmed
      # methods.
      # We put these methods in this module so that they are positioned
      # above the policy in the inheritance chain. We can then override
      # the methods in our policy as needed and call super to access the
      # previous definition.
      #
      # @return [ACTIONS_MODULE] the module for holding actions currently
      #   defined on this class.
      def self.actions_module
        if const_defined?(ACTIONS_MODULE, _search_ancestors = false)
          mod = const_get(ACTIONS_MODULE)
        else
          mod = const_set(ACTIONS_MODULE, Module.new)
          include mod
        end

        mod
      end

      def _get_action_id(action, object_id = nil)
        if object_id.nil?
          _get_general_action_id!(action)
        else
          _get_action_on_object_id!(action)
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
        @_actions ||= {}
      end

      def _actions
        self.class._actions
      end

      def self._actions_on_objects
        @_actions_on_objects ||= {}
      end

      def _actions_on_objects
        self.class._actions_on_objects
      end
    end
  end
end
