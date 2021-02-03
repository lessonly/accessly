require "active_record"

module Accessly
  class PermittedActionOnObject < ActiveRecord::Base
    belongs_to :actor, polymorphic: true
    belongs_to :object, polymorphic: true

    before_create :set_uuid

    private

    def set_uuid
      return unless PermittedActionOnObject.columns_hash['id'].type == :uuid

      self.id = SecureRandom.uuid
    end
  end
end
