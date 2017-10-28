module Daru
  class Vector
    module BooleanOps
      # !@method eq
      #   Uses `==` and returns `true` for each **equal** entry
      #   @param [#==, Daru::Vector] If scalar object, compares it with each
      #     element in self. If Daru::Vector, compares elements with same indexes.
      #   @example (see #where)
      # !@method not_eq
      #   Uses `!=` and returns `true` for each **unequal** entry
      #   @param [#!=, Daru::Vector] If scalar object, compares it with each
      #     element in self. If Daru::Vector, compares elements with same indexes.
      #   @example (see #where)
      # !@method lt
      #   Uses `<` and returns `true` for each entry **less than** the supplied object
      #   @param [#<, Daru::Vector] If scalar object, compares it with each
      #     element in self. If Daru::Vector, compares elements with same indexes.
      #   @example (see #where)
      # !@method lteq
      #   Uses `<=` and returns `true` for each entry **less than or equal to** the supplied object
      #   @param [#<=, Daru::Vector] If scalar object, compares it with each
      #     element in self. If Daru::Vector, compares elements with same indexes.
      #   @example (see #where)
      # !@method mt
      #   Uses `>` and returns `true` for each entry **more than** the supplied object
      #   @param [#>, Daru::Vector] If scalar object, compares it with each
      #     element in self. If Daru::Vector, compares elements with same indexes.
      #   @example (see #where)
      # !@method mteq
      #   Uses `>=` and returns `true` for each entry **more than or equal to** the supplied object
      #   @param [#>=, Daru::Vector] If scalar object, compares it with each
      #     element in self. If Daru::Vector, compares elements with same indexes.
      #   @example (see #where)

      # Define the comparator methods with metaprogramming. See documentation
      # written above for functionality of each method. Use these methods with the
      # `where` method to obtain the corresponding Vector/DataFrame.
      {
        eq: :==,
        not_eq: :!=,
        lt: :<,
        lteq: :<=,
        mt: :>,
        mteq: :>=
      }.each do |method, operator|
        define_method(method) do |other|
          mod = Daru::Core::Query
          if other.is_a?(Daru::Vector)
            mod.apply_vector_operator operator, self, other
          else
            mod.apply_scalar_operator operator, @data, other
          end
        end
        alias_method operator, method if operator != :== && operator != :!=
      end
      alias :gt :mt
      alias :gteq :mteq

      # Comparator for checking if any of the elements in *other* exist in self.
      #
      # @param [Array, Daru::Vector] other A collection which has elements that
      #   need to be checked for in self.
      # @example Usage of `in`.
      #   vector = Daru::Vector.new([1,2,3,4,5])
      #   vector.where(vector.in([3,5]))
      #   #=>
      #   ##<Daru::Vector:82215960 @name = nil @size = 2 >
      #   #    nil
      #   #  2   3
      #   #  4   5
      def in(other)
        other = Hash[other.zip(Array.new(other.size, 0))]
        Daru::Core::Query::BoolArray.new(
          @data.each_with_object([]) do |d, memo|
            memo << (other.key?(d) ? true : false)
          end
        )
      end

      # Return a new vector based on the contents of a boolean array. Use with the
      # comparator methods to obtain meaningful results. See this notebook for
      # a good overview of using #where.
      #
      # @param bool_array [Daru::Core::Query::BoolArray, Array<TrueClass, FalseClass>] The
      #   collection containing the true of false values. Each element in the Vector
      #   corresponding to a `true` in the bool_arry will be returned alongwith it's
      #   index.
      # @example Usage of #where.
      #   vector = Daru::Vector.new([2,4,5,51,5,16,2,5,3,2,1,5,2,5,2,1,56,234,6,21])
      #
      #   # Simple logic statement passed to #where.
      #   vector.where(vector.eq(5).or(vector.eq(1)))
      #   # =>
      #   ##<Daru::Vector:77626210 @name = nil @size = 7 >
      #   #    nil
      #   #  2   5
      #   #  4   5
      #   #  7   5
      #   # 10   1
      #   # 11   5
      #   # 13   5
      #   # 15   1
      #
      #   # A somewhat more complex logic statement
      #   vector.where((vector.eq(5) | vector.lteq(1)) & vector.in([4,5,1]))
      #   #=>
      #   ##<Daru::Vector:81072310 @name = nil @size = 7 >
      #   #    nil
      #   #  2   5
      #   #  4   5
      #   #  7   5
      #   # 10   1
      #   # 11   5
      #   # 13   5
      #   # 15   1
      def where(bool_array)
        Daru::Core::Query.vector_where self, bool_array
      end
    end
  end
end
