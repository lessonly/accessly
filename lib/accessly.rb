require "accessly/version"
require "accessly/query"
require "accessly/permission/grant"
require "accessly/permission/revoke"
require "accessly/models/permitted_action"
require "accessly/models/permitted_action_on_object"

module Accessly

  unless defined?(GrantError) == "constant" && GrantError.class == Class
    GrantError = Class.new(StandardError)
  end

  unless defined?(RevokeError) == "constant" && RevokeError.class == Class
    RevokeError = Class.new(StandardError)
  end

<<<<<<< Updated upstream
=======
  unless defined?(ListError) == "constant" && ListError.class == Class
    ListError = Class.new(StandardError)
  end

>>>>>>> Stashed changes
  # Accessly's tables are prefixed with accessly_ to
  # prevent any naming conflicts with other tables in the database.
  def self.table_name_prefix
    "accessly_"
  end
end
