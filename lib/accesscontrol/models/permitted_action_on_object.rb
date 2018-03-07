require "active_record"

module AccessControl
  class PermittedActionOnObject < ActiveRecord::Base
    belongs_to :actor, polymorphic: true
  end
end
