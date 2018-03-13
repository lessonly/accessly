# TODO: Write tests for this
module AccessControl
  class WhereTuple

    InconsistentTupleSizeException = Class.new(ArgumentError)

    # Allows for clauses like `WHERE (user_id, post_id) IN ((123, 456), (987, 654))`.
    # JOINing against other tables may cause PG::AmbiguousColumn errors when two of the
    # JOINed tables have columns of the same name.
    #
    # *NOTE* This method has the potential for SQL injection abuse. You must make sure
    # that column names are SQL safe. You can do this by ensuring only hard-coded column
    # names are used in calls to this method. Tuple values are sanitized here.
    #
    # Use like this:
    # `AccessControl::WhereTuple.where_in([:user_id, :post_id], [[123, 456], [987, 654]])`
    #
    # @param query [ActiveRecord::Relation] The relation on which to append the where clause
    # @param column_names [Array] An array of symbols or strings naming the columns to be compared in order
    # @param tuples [Array] An array of arrays, each of which contains a set of values for each of the columns, in the same order
    # @return [ActiveRecord::Relation]
    def self.where_in(query, column_names, tuples)
      tuple_size = column_names.size
      validate_tuple_size(column_names, tuples, tuple_size)
      return query.all if tuple_size.zero?

      tuples_count = tuples.size
      return query.none if tuples_count.zero?

      column_names_sql = column_names.map(&:to_s).join(", ")
      tuples_sql_array = tuples_count.times.to_a.map do |n|
        "(#{tuple_size.times.to_a.map { |x| "?" }.join(", ")})"
      end

      query.where("(#{column_names_sql}) IN (#{tuples_sql_array.join(", ")})", *tuples.flatten)
    end

    private

    def self.validate_tuple_size(column_names, tuples, tuple_size)
      # Invalid if the number of columns is different from the tuple size
      if column_names.size != tuple_size
        raise InconsistentTupleSizeException.new("Column count (#{column_names.size}) does not match tuple size (#{tuple_size})")
      end

      # Invalid if tuples are different sizes
      if tuples.any? { |tuple| tuple.size != tuple_size }
        raise InconsistentTupleSizeException.new("Tuple sizes are not consistent")
      end
    end
  end
end
