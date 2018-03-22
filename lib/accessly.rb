require "accessly/version"
require "accessly/query"

module Accessly

  unless defined?(GrantError) == "constant" && GrantError.class == Class
    GrantError = Class.new(StandardError)
  end

  unless defined?(RevokeError) == "constant" && RevokeError.class == Class
    RevokeError = Class.new(StandardError)
  end

  # Accessly's tables are prefixed with accessly_ to
  # prevent any naming conflicts with other tables in the database.
  def self.table_name_prefix
    "accessly_"
  end
end
