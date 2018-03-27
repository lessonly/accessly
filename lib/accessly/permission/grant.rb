module Accessly
  module Permission
    class Grant < Accessly::Base

      # Create an instance of Accessly::Permission::Grant
      # Pass in an ActiveRecord::Base for actor
      #
      # @param actor [ActiveRecord::Base] The actor to grant permission
      def initialize(actor)
        super(actor)
        @actor = case actor
        when ActiveRecord::Base
          actor
        else
          raise Accessly::GrantError.new("Actor is not an ActiveRecord::Base object")
        end
      end

      # Grant a permission to an actor.
      # @return [nil]
      # @overload grant!(action_id, namespace)
      #   Allow permission on a general action in the given namespace.
      #   A grant is universally unique and is enforced at the database level.
      #
      #   @param action_id [Integer] The action to grant for the object
      #   @param namespace [String] The namespace of the given action_id.
      #   @raise [Accessly::GrantError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Allow the user access to posts for action id 3
      #     Accessly::Permission::Grant.new(user).grant!(3, "posts")
      #     # Allow the user access to posts for action id 3 on a segment
      #     Accessly::Permission::Grant.new(user).on_segment(1).grant!(3, "posts")
      #
      # @overload grant!(action_id, namespace, namespace_id)
      #   Allow permission on a namespaced object.
      #   A grant is universally unique and is enforced at the database level.
      #
      #   @param action_id [Integer] The action to grant for the object
      #   @param namespace [ActiveRecord::Base] The ActiveRecord model that receives a permission grant.
      #   @param namespace_id [Integer] The id of the ActiveRecord object which receives a permission grant
      #   @raise [Accessly::GrantError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Allow the user access to Post 7 for action id 3
      #     Accessly::Permission::Grant.new(user).grant!(3, Post, 7)
      #     # Allow the user access to Post 7 for action id 3 on a segment
      #     Accessly::Permission::Grant.new(user).on_segment(1).grant!(3, Post, 7)
      def grant!(action_id, namespace, namespace_id = nil)
        if namespace_id.nil?
          general_action_grant(action_id, namespace)
        else
          object_action_grant(action_id, namespace, namespace_id)
        end
      end

      private

      def general_action_grant(action_id, namespace)
        Accessly::PermittedAction.create!(
          id: SecureRandom.uuid,
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          namespace: String(namespace)
        )
        nil
      rescue ActiveRecord::RecordNotUnique
        nil
      rescue => e
        raise Accessly::GrantError.new("Could not grant action #{action_id} on namespace #{namespace} for actor #{@actor} because #{e}")
      end

      def object_action_grant(action_id, namespace, namespace_id)
        Accessly::PermittedActionOnObject.create!(
          id: SecureRandom.uuid,
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          namespace: String(namespace),
          namespace_id: namespace_id
        )
        nil
      rescue ActiveRecord::RecordNotUnique
        nil
      rescue => e
        raise Accessly::GrantError.new("Could not grant action #{action_id} on namespace #{namespace} with id #{namespace_id} for actor #{@actor} because #{e}")
      end
    end
  end
end
