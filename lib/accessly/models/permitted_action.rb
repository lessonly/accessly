require "active_record"

module Accessly
  class PermittedAction < ActiveRecord::Base
    belongs_to :actor, polymorphic: true
  end
end
