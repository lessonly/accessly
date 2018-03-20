require "accesscontrol/version"
require "accesscontrol/query"

module AccessControl

  unless defined?(GrantError) == "constant" && GrantError.class == Class
    GrantError = Class.new(StandardError)
  end

  unless defined?(RevokeError) == "constant" && RevokeError.class == Class
    RevokeError = Class.new(StandardError)
  end

  unless defined?(ListError) == "constant" && ListError.class == Class
    ListError = Class.new(StandardError)
  end

  # AccessControl's tables are prefixed with access_control to
  # prevent any naming conflicts with other tables in the database.
  def self.table_name_prefix
    "access_control_"
  end
end
