module Accessly
  module Permission
    class Revoke < Accessly::Base

      # Create an instance of Accessly::Permission::Revoke
      # Pass in an ActiveRecord::Base for actor
      #
      # @param actor [ActiveRecord::Base] The actor to revoke permission
      def initialize(actor)
        super(actor)
        @actor = case actor
        when ActiveRecord::Base
          actor
        else
          raise Accessly::RevokeError.new("Actor is not an ActiveRecord::Base object")
        end
      end

      # Revoke a permission for an actor.
      # @return [nil]
      # @overload revoke!(action_id, namespace)
      #   Revoke permission on a general action in the given namespace.
      #
      #   @param action_id [Integer] The action to revoke
      #   @param namespace [String] The namespace of the given action_id.
      #   @raise [Accessly::RevokeError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Remove user access to posts for action id 3
      #     Accessly::Permission::Revoke.new(user).revoke!(3, Post)
      #     # Remove user access to posts for action id 3 on a segment
      #     Accessly::Permission::Revoke.new(user).on_segment(1).revoke!(3, Post)
      #
      # @overload revoke!(action_id, namespace, namespace_id)
      #   Revoke permission on an ActiveRecord object.
      #
      #   @param action_id [Integer] The action to revoke
      #   @param namespace [Class] The namespace to remove a permission.
      #   @param namespace_id [Integer] The id of the namespaced object that removes a permission
      #   @raise [Accessly::RevokeError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Remove user access to Post 7 for action id 3
      #     Accessly::Permission::Revoke.new(user).revoke!(3, Post, 7)
      #     # Remove user access to Post 7 for action id 3 on a segment
      #     Accessly::Permission::Revoke.new(user).on_segment(1).revoke!(3, Post, 7)
      def revoke!(action_id, namespace, namespace_id = nil)
        if namespace_id.nil?
          general_action_revoke(action_id, namespace)
        else
          object_action_revoke(action_id, namespace, namespace_id)
        end
      end

      private

      def general_action_revoke(action_id, namespace)
        Accessly::PermittedAction.where(
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          namespace: String(namespace)
        ).delete_all
        nil
      rescue => e
        raise Accessly::RevokeError.new("Could not revoke action #{action_id} on object #{namespace} for actor #{@actor} because #{e}")
      end

      def object_action_revoke(action_id, namespace, namespace_id)
        Accessly::PermittedActionOnObject.where(
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          namespace: String(namespace),
          namespace_id: namespace_id
        ).delete_all
        nil
      rescue => e
        raise Accessly::RevokeError.new("Could not revoke #{action_id} on namespace #{namespace} with id #{namespace_id} for actor #{@actor} because #{e}")
      end
    end
  end
end
