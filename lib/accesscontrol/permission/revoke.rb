module AccessControl
  module Permission
    class Revoke < AccessControl::Base

      # Create an instance of AccessControl::Permission::Revoke
      # Pass in an ActiveRecord::Base for actor
      #
      # @param actor [ActiveRecord::Base] The actor to revoke permission
      def initialize(actor)
        super(actor)
        @actor = case actor
        when ActiveRecord::Base
          actor
        else
          raise AccessControl::RevokeError.new("Actor is not an ActiveRecord::Base object")
        end
      end

      # Revoke a permission for an actor.
      # @return [nil]
      # @overload revoke(action_id, object_type)
      #   Reoking permission on a general action in the given namespace represented by object_type.
      #
      #   @param action_id [Integer] The action to revoke
      #   @param object_type [String] The namespace of the given action_id.
      #   @raise [AccessControl::RevokeError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Remove user access to posts for action id 3
      #     AccessControl::Permission::Revoke.new(user).revoke(3, Post)
      #     # Remove user access to posts for action id 3 on a segment
      #     AccessControl::Permission::Revoke.new(user).on_segment(1).revoke(3, Post)

      # @overload revoke(action_id, object_type, object_id)
      # Revoke permission on an ActiveRecord object.
      #
      #   @param action_id [Integer] The action to revoke
      #   @param object_type [ActiveRecord::Base] The ActiveRecord model that removes a permission.
      #   @param object_id [Integer] The id of the ActiveRecord object that removes a permission
      #   @raise [AccessControl::RevokeError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Remove user access to Post 7 for action id 3
      #     AccessControl::Permission::Revoke.new(user).revoke(3, Post, 7)
      #     # Remove user access to Post 7 for action id 3 on a segment
      #     AccessControl::Permission::Revoke.new(user).on_segment(1).revoke(3, Post, 7)
      def revoke(action_id, object_type, object_id = nil)
        if object_id.nil?
          general_action_revoke(action_id, object_type)
        else
          object_action_revoke(action_id, object_type, object_id)
        end
      end

      private

      def general_action_revoke(action_id, object_type)
        AccessControl::PermittedAction.where(
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          object_type: String(object_type)
        ).delete_all
        nil
      rescue => e
        raise AccessControl::RevokeError.new("Could not revoke action #{action_id} on object #{object_type} for actor #{@actor} because #{e}")
      end

      def object_action_revoke(action_id, object_type, object_id)
        AccessControl::PermittedActionOnObject.where(
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          object_type: String(object_type),
          object_id: object_id
        ).delete_all
        nil
      rescue => e
        raise AccessControl::RevokeError.new("Could not revoke #{action_id} on object #{object_type} with id #{object_id} for actor #{@actor} because #{e}")
      end
    end
  end
end
