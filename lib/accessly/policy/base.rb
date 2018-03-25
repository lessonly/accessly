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

      def accessly_query
        @_accessly_query ||= Accessly::Query.new(actor)
      end

      private

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

      def self._define_action_method(action, action_id)
        unless method_defined?("#{action}?")
          define_method("#{action}?") do |*args|
            _can_do_action?(action, action_id, args.first)
          end
        end
      end

      def _can_do_action?(action, action_id, object)
        if object.nil?
          _can_do_action_without_object?(action, action_id)
        else
          _can_do_action_with_object?(action, action_id, object)
        end
      end

      def _can_do_action_without_object?(action, action_id)
        if !_actions[action].nil?
          accessly_query.can?(action_id, namespace)
        else
          raise ArgumentError.new("#{action} is not defined as a general action for #{self.class.name}")
        end
      end

      def _can_do_action_with_object?(action, action_id, object)
        object_id = object.respond_to?(:id) ? object.id : object

        if !_actions_on_objects[action].nil?
          accessly_query.can?(action_id, namespace, object_id)
        else
          raise ArgumentError.new("#{action} is not defined as an action-on-object for #{self.class.name}")
        end
      end
    end
  end
end
