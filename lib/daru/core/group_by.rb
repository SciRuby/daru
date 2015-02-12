module Daru
  module Core
    class GroupBy

      attr_reader :groups

      def initialize context, names
        @groups = {}
        @non_group_vectors = context.vectors.to_a - names
        @context = context
        vectors = names.map { |vec| context.vector[vec].to_a }
        tuples  = vectors[0].zip(*vectors[1..-1])
        keys    = tuples.uniq.sort

        keys.each do |key|
          @groups[key] = all_indices_for(tuples, key)
        end
        @groups.freeze
      end

      def size
        index = 
        if multi_indexed_grouping?
          Daru::MultiIndex.new symbolize(@groups.keys)
        else
          Daru::Index.new symbolize(@groups.keys.flatten)
        end

        values = @groups.values.map { |e| e.size }
        Daru::Vector.new(values, index: index, name: :size)
      end

      def head quantity=5
        select_groups_from :first, quantity
      end

      def tail quantity=5
        select_groups_from :last, quantity
      end

      # Calculate mean of numeric groups, excluding missing values.
      def mean
        apply_method :numeric, :mean
      end

      # Calculate the median of numeric groups, excluding missing values.
      def median
        apply_method :numeric, :median
      end

      # Calculate sum of numeric groups, excluding missing values.
      def sum
        apply_method :numeric, :sum
      end

      def count
        width = @non_group_vectors.size
        Daru::DataFrame.new([size]*width, order: @non_group_vectors)
      end

      # Calculate sample standard deviation of numeric vector groups, excluding 
      # missing values.
      def std
        apply_method :numeric, :std
      end

      # Find the max element of each numeric vector group.
      def max
        apply_method :numeric, :max
      end

      # Find the min element of each numeric vector group.
      def min
        apply_method :numeric, :min
      end

      # Returns one of the selected groups as a DataFrame.
      def get_group group
        indexes   = @groups[group]
        elements  = []

        @context.each_vector do |vector|
          elements << vector.to_a
        end
        rows = []
        transpose = elements.transpose

        indexes.each do |idx|
          rows << transpose[idx]
        end
        Daru::DataFrame.rows(rows, index: @context.index[indexes], order: @context.vectors)
      end

     private 

      def select_groups_from method, quantity
        selection     = @context
        rows, indexes = [], []

        @groups.each_value do |index|
          index.send(method, quantity).each do |idx|
            rows << selection.row[idx].to_a
            indexes << idx
          end
        end
        indexes.flatten!

        Daru::DataFrame.rows(rows, order: @context.vectors, index: indexes)
      end

      def apply_method method_type, method
        multi_index = multi_indexed_grouping?
        rows, order = [], []

        @groups.each do |group, indexes|
          single_row = []
          @non_group_vectors.each do |ngvector|
            vector = @context.vector[ngvector]
            if method_type == :numeric and vector.type == :numeric
              slice = vector[*indexes]

              single_row << (slice.is_a?(Numeric) ? slice : slice.send(method))
              order << ngvector
            end
          end 

          rows << single_row
        end

        index = symbolize @groups.keys
        index = multi_index ? Daru::MultiIndex.new(index) : Daru::Index.new(index.flatten)
        order = symbolize order
        order = 
        if order.all?{ |e| e.is_a?(Array) }
          Daru::MultiIndex.new(order)
        else
          Daru::Index.new(order)
        end

        Daru::DataFrame.new(rows.transpose, index: index, order: order)
      end

      def all_indices_for arry, element
        found, index, indexes = -1, -1, []
        while found
          found = arry[index+1..-1].index(element)
          if found
            index = index + found + 1
            indexes << index
          end
        end
        indexes
      end

      def symbolize arry
        if arry.all? { |e| e.is_a?(Array) }
          arry.map! do |sub_arry|
            sub_arry.map! do |e|
              e.is_a?(Numeric) ? e : e.to_sym
            end
          end
        else
          arry.map! { |e| e.is_a?(Numeric) ? e : e.to_sym }
        end
      end

      def multi_indexed_grouping?
        @groups.keys[0][1] ? true : false
      end
    end
  end
end