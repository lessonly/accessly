module AccessControl
  module Permission
    class Grant < AccessControl::Base

      # Create an instance of AccessControl::Permission::Grant
      # Pass in an ActiveRecord::Base for actor
      #
      # @param actor [ActiveRecord::Base] The actor to grant permission
      def initialize(actor)
        super(actor)
        @actor = case actor
        when ActiveRecord::Base
          actor
        else
          raise AccessControl::GrantError.new("Actor is not an ActiveRecord::Base object")
        end
      end

      # Grant a permission to an actor.
      # @return [nil]
      # @overload grant(action_id, object_type)
      #   Allow permission on a general action in the given namespace represented by object_type.
      #   A grant is universally unique and is enforced at the database level.
      #
      #   @param action_id [Integer] The action to grant for the object
      #   @param object_type [String] The namespace of the given action_id.
      #   @raise [AccessControl::GrantError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Allow the user access to posts
      #     AccessControl::Query.new(user).grant(3, "posts")

      # @overload grant(action_id, object_type, object_id)
      # Allow permission on an ActiveRecord object.
      # A grant is universally unique and is enforced at the database level.
      #
      #   @param action_id [Integer] The action to grant for the object
      #   @param object_type [ActiveRecord::Base] The ActiveRecord model that receives a permission grant.
      #   @param object_id [Integer] The id of the ActiveRecord object which receives a permission grant
      #   @raise [AccessControl::GrantError] if the operation does not succeed
      #   @return [nil] Returns nil if successful
      #
      #   @example
      #     # Allow the user access to Post 7
      #     AccessControl::Query.new(user).grant(3, Post, 7)
      def grant(action_id, object_type, object_id = nil)
        if object_id.nil?
          general_action_grant(action_id, object_type)
        else
          object_action_grant(action_id, object_type, object_id)
        end
      end

      private

      def general_action_grant(action_id, object_type)
        AccessControl::PermittedAction.create!(
          id: SecureRandom.uuid,
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          object_type: String(object_type)
        )
        nil
      rescue ActiveRecord::RecordNotUnique
        nil
      rescue => e
        raise AccessControl::GrantError.new("Could not grant action #{action_id} on object #{object_type} for actor #{@actor} because #{e}")
      end

      def object_action_grant(action_id, object_type, object_id)
        AccessControl::PermittedActionOnObject.create!(
          id: SecureRandom.uuid,
          segment_id: @segment_id,
          actor: @actor,
          action: action_id,
          object_type: String(object_type),
          object_id: object_id
        )
        nil
      rescue ActiveRecord::RecordNotUnique
        nil
      rescue => e
        raise AccessControl::GrantError.new("Could not grant action #{action_id} on object #{object_type} with id #{object_id} for actor #{@actor} because #{e}")
      end
    end
  end
end
