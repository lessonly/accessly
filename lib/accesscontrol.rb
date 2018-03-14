require "accesscontrol/version"
require "accesscontrol/query"

module AccessControl
  # AccessControl's tables are prefixed with access_control to
  # prevent any naming conflicts with other tables in the database.
  def self.table_name_prefix
    "access_control_"
  end
end
