require "accessly/permitted_actions/query"
require "accessly/permitted_actions/on_object_query"


module Accessly
  class Base

    # Create an instance of Accessly::Base.
    # Lookups are cached in inherited object(s) to prevent redundant calls to the database.
    # Pass in a Hash or ActiveRecord::Base for actors if the actor(s)
    # inherit some permissions from other actors in the system. This may happen
    # when you have a user in one or more groups or organizations with their own
    # access control permissions.
    #
    # @param actors [Hash, ActiveRecord::Base] The actor(s) we're checking permission(s)
    def initialize(actors)
      @segment_id = -1
      @actors = case actors
                when Hash
                  actors
                else
                  { actors.class.name => actors.id }
                end
    end

    # @param segment_id [Integer] The segment to further separate permissions requests
    # @return [Accessly::Base] returns the object caller
    def on_segment(segment_id)
      @segment_id = segment_id
      self
    end
  end
end
