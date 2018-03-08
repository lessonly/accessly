require "accesscontrol/version"
require "accesscontrol/records"
require "accesscontrol/general"

# AccessControl is the interface that hides the implementation
# of the data layer. Tell AccessControl when to grant and revoke
# permissions, ask it whether an actor has permission on a
# record, ask it for a list of permitted records for the record
# type, and ask it whether an actor has a general permission not
# related to any certain record or record type.
module AccessControl
  module_function

  # AccessControl's tables are prefixed with access_control to
  # prevent any naming conflicts with other tables in the database.
  def self.table_name_prefix
    "access_control_"
  end
 
  # Check whether an actor has a given permission.
  # @return [Boolean]
  # @overload can?(actor, action_id, namespace)
  #   Ask whether the actor has permission to perform action_id
  #   in the given namespace. Multiple actions can have the same id
  #   as long as their namespace is different. The namespace can be
  #   any String. We recommend using namespace to group a class of
  #   permissions, such as to group parts of a particular feature
  #   in your application.
  #
  #   @param actor [ActiveRecord::Base] The actor we're checking for permission on.
  #   @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
  #   @param namespace [String] The namespace of the given action_id.
  #   @return [Boolean] Returns true if actor has been granted the permission, false otherwise.
  #
  #   @example
  #     # Can the user perform the action with id 3 for posts?
  #     AccessControl.can?(user, 3, "posts")
  #
  # @overload can?(actor, action_id, object_type, object_id)
  #   Ask whether the actor has permission to perform action_id
  #   on a given record.
  #
  #   @param actor [ActiveRecord::Base] The actor we're checking for permission on.
  #   @param action_id [Integer, Array<Integer>] The action or actions we're checking whether the actor has. If this is an array, then the check is ORed.
  #   @param object_type [ActiveRecord::Base] The ActiveRecord model which we're checking for permission on.
  #   @param object_id [Integer] The id of the ActiveRecord object which we're checking for permission on.
  #   @return [Boolean] Returns true if actor has been granted the permission on the specified record, false otherwise.
  #
  #   @example
  #     # Can the user perform the action with id 5 for the Post with id 7?
  #     AccessControl.can?(user, 5, Post, 7)
  def can?(actor, action_id, object_type, object_id = nil)
    if object_id.nil?
      General.can?(actor, action_id, object_type)
    else
      Records.can?(actor, action_id, object_type, object_id)
    end
  end

  # Returns an ActiveRecord::Relation of object_type containing the
  # records on which the actor has permission to perform action_id.
  #
  # @param actor [ActiveRecord::Base] The actor we're loading records for.
  # @param action_id [Integer] The action we're checking whether the actor has.
  # @param object_type [ActiveRecord::Base] The ActiveRecord model to be loaded.
  # @return [ActiveRecord::Relation]
  #
  # @example
  #   # Give me the list of Posts on which the user has permission to perform action_id 3
  #   AccessControl.list(user, 3, Post)
  # @example
  #   # You can chain ActiveRecord query methods to further filter the results
  #   # Give me the list of Posts on which the user has permission to perform action_id 3, and which have the title "Untitled", but limit to 5 results
  #   AccessControl.list(user, 3, Post).where(title: "Untitled").limit(5)
  def list(actor, action_id, object_type)
    Records.list(actor, action_id, object_type)
  end

  def grant(actor, action_id, object_type, object_id = nil)
  end

  def revoke(actor, action_id, object_type, object_id = nil)
  end

end
