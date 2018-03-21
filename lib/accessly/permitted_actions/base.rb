require "accessly/query_builder"

module Accessly
  module PermittedActions
    class Base

      def initialize(actors, segment_id)
        @actors = actors
        @segment_id = segment_id
      end

      protected

      def past_lookups
        @_past_lookups ||= {}
      end

      def find_or_set_value(*keys, &query)
        found_value = past_lookups.dig(*keys)

        if found_value.nil?
          found_value = query.call
          set_value(*keys, value: found_value)
        end

        found_value
      end

      def set_value(*keys, value:)
        lookup = past_lookups
        keys[0..-2].each do |key|
          lookup[key] ||= {}
          lookup = lookup[key]
        end

        lookup[keys[-1]] = value
      end
    end
  end
end
