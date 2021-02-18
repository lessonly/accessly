require "active_record"

module Accessly
  class PermittedAction < ActiveRecord::Base
    belongs_to :actor, polymorphic: true

    before_create :set_uuid

    private

    def set_uuid
      return unless PermittedAction.columns_hash['id'].type == :uuid

      self.id = SecureRandom.uuid
    end
  end
end
