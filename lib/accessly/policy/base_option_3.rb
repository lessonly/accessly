module Accessly
  module Policy
    class BaseOption3

      attr_reader :actor

      def initialize(actor)
        @actor = actor
      end

      def self.actions(actions)
        _actions.merge!(actions)
      end

      def self.actions_on_objects(actions_on_objects)
        _actions_on_objects.merge!(actions_on_objects)
      end

      def self.override_action_check(action, block)
        overridden_action_checks[action] = block
      end

      def self.override_object_action_check(action, block)
        overriden_object_action_checks[action] = block
      end

      def self.object_type
        raise NotImplementedError.new("object_type must be implemented")
      end

      def can?(action, object = nil)
        if object.nil?
          _can_do_action_without_object?(action, _actions[action])
        else
          _can_do_action_with_object?(action, _actions_on_objects[action], object)
        end
      end

      def object_type
        self.class.object_type
      end

      def accessly_query
        @_accessly_query ||= Accessly::Query.new(actor)
      end

      private

      def self.overridden_action_checks
        @@_overridden_action_checks ||= {}
      end

      def self.overriden_object_action_checks
        @@_overriden_object_action_checks ||= {}
      end

      def overridden_action_checks
        self.class.overridden_action_checks
      end

      def overriden_object_action_checks
        self.class.overriden_object_action_checks
      end

      def self._actions
        @@_actions ||= {}
      end

      def self._actions_on_objects
        @@_actions_on_objects ||= {}
      end

      def _actions
        self.class._actions
      end

      def _actions_on_objects
        self.class._actions_on_objects
      end

      def _can_do_action_without_object?(action, action_id)
        if !_actions[action].nil?
          custom_action = overridden_action_checks[action]

          result = if !custom_action.nil?
            custom_action.call(actor)
          end

          if result.nil?
            accessly_query.can?(action_id, object_type)
          else
            result
          end
        else
          raise ArgumentError.new("#{action} is not defined as a general action for #{self.class.name}")
        end
      end

      def _can_do_action_with_object?(action, action_id, object)
        if !_actions_on_objects[action].nil?
          custom_action = overriden_object_action_checks[action]

          result = if !custom_action.nil?
            custom_action.call(actor, object)
          end

          if result.nil?
            accessly_query.can?(action_id, object.class, object.id)
          else
            result
          end
        else
          raise ArgumentError.new("#{action} is not defined as an action-on-object for #{self.class.name}")
        end
      end
    end
  end
end
