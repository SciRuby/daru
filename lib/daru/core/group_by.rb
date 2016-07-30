module Daru
  module Core
    class GroupBy
      attr_reader :groups

      # Iterate over each group created by group_by. A DataFrame is yielded in
      # block.
      def each_group
        groups.keys.each do |k|
          yield get_group(k)
        end
      end

      TUPLE_SORTER = lambda do |a, b|
        if a && b
          a.compact <=> b.compact
        else
          a ? 1 : -1
        end
      end

      def initialize context, names
        @groups = {}
        @non_group_vectors = context.vectors.to_a - names
        @context = context
        vectors = names.map { |vec| context[vec].to_a }
        tuples  = vectors[0].zip(*vectors[1..-1])
        keys    = tuples.uniq.sort(&TUPLE_SORTER)

        keys.each do |key|
          @groups[key] = all_indices_for(tuples, key)
        end
        @groups.freeze
      end

      # Get a Daru::Vector of the size of each group.
      def size
        index =
          if multi_indexed_grouping?
            Daru::MultiIndex.from_tuples @groups.keys
          else
            Daru::Index.new @groups.keys.flatten
          end

        values = @groups.values.map(&:size)
        Daru::Vector.new(values, index: index, name: :size)
      end

      # Get the first group
      def first
        head(1)
      end

      # Get the last group
      def last
        tail(1)
      end

      # Get the top 'n' groups
      # @param quantity [Fixnum] (5) The number of groups.
      # @example Usage of head
      #   df = Daru::DataFrame.new({
      #     a: %w{foo bar foo bar   foo bar foo foo},
      #     b: %w{one one two three two two one three},
      #     c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      #     d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
      #   })
      #   df.group_by([:a, :b]).head(1)
      #   # =>
      #   # #<Daru::DataFrame:82745170 @name = d7003f75-5eb9-4967-9303-c08dd9160224 @size = 6>
      #   #                     a          b          c          d
      #   #          1        bar        one          2         22
      #   #          3        bar      three          1         44
      #   #          5        bar        two          6         66
      #   #          0        foo        one          1         11
      #   #          7        foo      three          8         88
      #   #          2        foo        two          3         33
      def head quantity=5
        select_groups_from :first, quantity
      end

      # Get the bottom 'n' groups
      # @param quantity [Fixnum] (5) The number of groups.
      # @example Usage of tail
      #   df = Daru::DataFrame.new({
      #     a: %w{foo bar foo bar   foo bar foo foo},
      #     b: %w{one one two three two two one three},
      #     c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      #     d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
      #   })
      #   # df.group_by([:a, :b]).tail(1)
      #   # =>
      #   # #<Daru::DataFrame:82378270 @name = 0623db46-5425-41bd-a843-99baac3d1d9a @size = 6>
      #   #                     a          b          c          d
      #   #          1        bar        one          2         22
      #   #          3        bar      three          1         44
      #   #          5        bar        two          6         66
      #   #          6        foo        one          3         77
      #   #          7        foo      three          8         88
      #   #          4        foo        two          3         55
      def tail quantity=5
        select_groups_from :last, quantity
      end

      # Calculate mean of numeric groups, excluding missing values.
      # @example Usage of mean
      #   df = Daru::DataFrame.new({
      #     a: %w{foo bar foo bar   foo bar foo foo},
      #     b: %w{one one two three two two one three},
      #     c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      #     d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
      #   df.group_by([:a, :b]).mean
      #   # =>
      #   # #<Daru::DataFrame:81097450 @name = 0c32983f-3e06-451f-a9c9-051cadfe7371 @size = 6>
      #   #                         c          d
      #   # ["bar", "one"]          2         22
      #   # ["bar", "three"]        1         44
      #   # ["bar", "two"]          6         66
      #   # ["foo", "one"]        2.0       44.0
      #   # ["foo", "three"]        8         88
      #   # ["foo", "two"]        3.0       44.0
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

      # Count groups, excludes missing values.
      # @example Using count
      #   df = Daru::DataFrame.new({
      #     a: %w{foo bar foo bar   foo bar foo foo},
      #     b: %w{one one two three two two one three},
      #     c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      #     d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
      #   })
      #   df.group_by([:a, :b]).count
      #   # =>
      #   # #<Daru::DataFrame:76900210 @name = 7b9cf55d-17f8-48c7-b03a-2586c6e5ec5a @size = 6>
      #   #                           c          d
      #   # ["bar", "one"]            1          1
      #   # ["bar", "two"]            1          1
      #   # ["bar", "three"]          1          1
      #   # ["foo", "one"]            2          2
      #   # ["foo", "three"]          1          1
      #   # ["foo", "two"]            2          2
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
      # @param group [Array] The group that is to be selected from those grouped.
      #
      # @example Getting a group
      #
      #   df = Daru::DataFrame.new({
      #         a: %w{foo bar foo bar   foo bar foo foo},
      #         b: %w{one one two three two two one three},
      #         c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
      #         d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
      #       })
      #   df.group_by([:a, :b]).get_group ['bar','two']
      #   #=>
      #   ##<Daru::DataFrame:83258980 @name = 687ee3f6-8874-4899-97fa-9b31d84fa1d5 @size = 1>
      #   #                    a          b          c          d
      #   #         5        bar        two          6         66
      def get_group group
        indexes   = @groups[group]
        elements  = @context.each_vector.map(&:to_a)
        transpose = elements.transpose
        rows      = indexes.each.map { |idx| transpose[idx] }

        new_index =
          begin
            @context.index[indexes]
          rescue IndexError
            indexes
          end

        Daru::DataFrame.rows(
          rows, index: new_index, order: @context.vectors
        )
      end

      # Iteratively applies a function to the values in a group and accumulates the result.
      # @param init (nil) The initial value of the accumulator.
      # @param block [Proc] A proc or lambda that accepts two arguments.  The first argument
      #                     is the accumulated result.  The second argument is a DataFrame row.
      # @example Usage of reduce
      #   df = Daru::DataFrame.new({
      #     a: ['a','b'] * 3,
      #     b: [1,2,3] * 2,
      #     c: 'A'..'F'
      #   })
      #   df.group_by([:a]).reduce('') { |result, row| result += row[:c]; result }
      #   # =>
      #   # #<Daru::Vector:70343147159900 @name = nil @size = 2 >
      #   #     nil
      #   #   a ACE
      #   #   b BDF
      def reduce(init=nil)
        result_hash = @groups.each_with_object({}) do |(group, indices), h|
          group_indices = indices.map { |v| @context.index.to_a[v] }

          grouped_result = init
          group_indices.each do |idx|
            grouped_result = yield(grouped_result, @context.row[idx])
          end

          h[group] = grouped_result
        end

        index =
          if multi_indexed_grouping?
            Daru::MultiIndex.from_tuples result_hash.keys
          else
            Daru::Index.new result_hash.keys.flatten
          end

        Daru::Vector.new(result_hash.values, index: index)
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
        order = @non_group_vectors.select do |ngvec|
          method_type == :numeric && @context[ngvec].type == :numeric
        end

        rows = @groups.map do |_group, indexes|
          order.map do |ngvector|
            slice = @context[ngvector][*indexes]
            slice.is_a?(Daru::Vector) ? slice.send(method) : slice
          end
        end

        index = apply_method_index
        order = Daru::Index.new(order)
        Daru::DataFrame.new(rows.transpose, index: index, order: order)
      end

      def apply_method_index
        if multi_indexed_grouping?
          Daru::MultiIndex.from_tuples(@groups.keys)
        else
          Daru::Index.new(@groups.keys.flatten)
        end
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

      def multi_indexed_grouping?
        return false unless @groups.keys[0]
        @groups.keys[0].size > 1 ? true : false
      end
    end
  end
end
