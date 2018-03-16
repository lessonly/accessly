require "accesscontrol/version"
require "accesscontrol/query"

module AccessControl

  unless defined?(CouldNotGrantError) == "constant" && CouldNotGrantError.class == Class
    CouldNotGrantError = Class.new(StandardError)
  end
  
  # AccessControl's tables are prefixed with access_control to
  # prevent any naming conflicts with other tables in the database.
  def self.table_name_prefix
    "access_control_"
  end
end
