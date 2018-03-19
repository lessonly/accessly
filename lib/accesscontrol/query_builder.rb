# TODO: Write tests for this
module AccessControl
  class QueryBuilder

    # Builds a query with a series of actors 'OR' together
    #
    # Use like this:
    # `AccessControl::QueryBuilder.with_actors(PermittedActionOnObject, {User => 1, Group => [2,3]})`
    #
    # @param query [ActiveRecord::Relation] The relation on which to append the where clause
    # @param actors [Hash] A hash of actors where the key is the object/classname and the value is an Integer or array of Integers
    # @return [ActiveRecord::Relation]
    def self.with_actors(query, actors)
      result_query = nil;
      actors.each do |key, value|
        result_query = if result_query.nil?
          query.where(actor_type: String(key), actor_id: value)
        else
          result_query.or(query.where(actor_type: String(key), actor_id: value))
        end
      end
      result_query
    end
  end
end
