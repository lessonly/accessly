require "active_record"

module Accessly
  class PermittedActionOnObject < ActiveRecord::Base
    belongs_to :actor, polymorphic: true
    belongs_to :object, polymorphic: true
  end
end
