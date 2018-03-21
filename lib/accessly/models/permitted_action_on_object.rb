require "active_record"

module Accessly
  class PermittedActionOnObject < ActiveRecord::Base
    belongs_to :actor, polymorphic: true
  end
end
