require "accesscontrol/version"
require "accesscontrol/query"

# AccessControl is the interface that hides the implementation
# of the data layer. Tell AccessControl when to grant and revoke
# permissions, ask it whether an actor has permission on a
# record, ask it for a list of permitted records for the record
# type, and ask it whether an actor has a general permission not
# related to any certain record or record type.
module AccessControl
  # AccessControl's tables are prefixed with access_control to
  # prevent any naming conflicts with other tables in the database.
  def self.table_name_prefix
    "access_control_"
  end
end
