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
      end

      def size
        
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

      def get_group
        
      end

     private 

      def apply_method method_type, method
        multi_index = @groups.keys[0][1] ? true : false
        rows, order = [], []

        @groups.each do |group, indexes|
          single_row = []
          @non_group_vectors.each do |ngvector|
            vector = @context.vector[ngvector]
            if method_type == :numeric and vector.type == :numeric
              slice = vector[*indexes]

              single_row << (slice.is_a?(Numeric) ? slice : slice.send(method))
              order << ngvector
            elsif method_type == :nonumeric
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
    end
  end
end