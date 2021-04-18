module Accessly
  module Permission
    class BulkRevoke
      # Revoke a given action for all actors.
      #
      # @param action_id [Integer] The action to revoke.
      # @param object_type [String] The namespace of the given action_id.
      #
      #   @example
      #     Remove all access for action id 3
      #     Accessly::Permission::BulkRevoke.new.revoke!(3)
      #   @example
      #     Remove all access to for action id 3 on a segment
      #     Accessly::Permission::BulkRevoke.new.on_segment(1).revoke!(3)
      #
      def revoke!(action_id, object_type)
        Accessly::PermittedAction.where(
          action: action_id,
          object_type: String(object_type)
        ).delete_all
        nil
      rescue StandardError => e
        raise Accessly::BulkRevokeError, <<~MSG
          "Could not revoke action #{action_id} because #{e}"
        MSG
      end
    end
  end
end
