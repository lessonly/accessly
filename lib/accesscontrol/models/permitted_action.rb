require "active_record"

module AccessControl
  class PermittedAction < ActiveRecord::Base
    belongs_to :actor, polymorphic: true
  end
end
