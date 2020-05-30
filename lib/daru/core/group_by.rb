module Daru
  module Core
    class GroupBy
      class << self
        extend Gem::Deprecate

        # @private
        def group_by_index_to_positions(indexes_with_positions, sort: false)
          index_to_positions = {}

          indexes_with_positions.each do |idx, position|
            (index_to_positions[idx] ||= []) << position
          end

          if sort # TODO: maybe add a more "stable" sorting option?
            sorted_keys = index_to_positions.keys.sort(&Daru::Core::GroupBy::TUPLE_SORTER)
            index_to_positions = sorted_keys.map { |k| [k, index_to_positions[k]] }.to_h
          end

          index_to_positions
        end
        alias get_positions_group_map_on group_by_index_to_positions
        deprecate :get_positions_group_map_on, :group_by_index_to_positions, 2019, 10

        # @private
        def get_positions_group_for_aggregation(multi_index, level=-1)
          raise unless multi_index.is_a?(Daru::MultiIndex)

          new_index = multi_index.dup
          new_index.remove_layer(level) # TODO: recheck code of Daru::MultiIndex#remove_layer

          group_by_index_to_positions(new_index.each_with_index)
        end

        # @private
        def get_positions_group_map_for_df(df, group_by_keys, sort: true)
          indexes_with_positions = df[*group_by_keys].to_df.each_row.map(&:to_a).each_with_index

          group_by_index_to_positions(indexes_with_positions, sort: sort)
        end

        # @private
        def group_map_from_positions_to_indexes(positions_group_map, index)
          positions_group_map.map { |k, positions| [k, positions.map { |pos| index.at(pos) }] }.to_h
        end

        # @private
        def df_from_group_map(df, group_map, remaining_vectors, from_position: true)
          return nil if group_map == {}

          new_index = group_map.flat_map { |group, values| values.map { |val| group + [val] } }
          new_index = Daru::MultiIndex.from_tuples(new_index)

          return Daru::DataFrame.new({}, index: new_index) if remaining_vectors == []

          new_rows_order = group_map.values.flatten
          new_df = df[*remaining_vectors].to_df.get_sub_dataframe(new_rows_order, by_position: from_position)
          new_df.index = new_index

          new_df
        end
      end

      # The group_by was done over the vectors in group_vectors; the remaining vectors are the non_group_vectors
      attr_reader :group_vectors, :non_group_vectors

      # lazy accessor/attr_reader for the attribute groups
      def groups
        @groups ||= GroupBy.group_map_from_positions_to_indexes(@groups_by_pos, @context.index)
      end
      alias :groups_by_idx :groups

      # lazy accessor/attr_reader for the attribute df
      def df
        @df ||= GroupBy.df_from_group_map(@context, @groups_by_pos, @non_group_vectors)
      end
      alias :grouped_df :df

      # Iterate over each group created by group_by. A DataFrame is yielded in
      # block.
      def each_group
        return to_enum(:each_group) unless block_given?

        groups.keys.each do |k|
          yield get_group(k)
        end
      end

      TUPLE_SORTER = lambda do |left, right|
        return -1 unless right
        return 1 unless left

        left = left.compact
        right = right.compact
        return left <=> right || 0 if left.length == right.length
        left.length <=> right.length
      end

      def initialize context, names
        @group_vectors     = names
        @non_group_vectors = context.vectors.to_a - names

        @context = context # TODO: maybe rename in @original_df

        # FIXME: It feels like we don't want to sort here. Ruby's #group_by
        # never sorts:
        #
        #   ['test', 'me', 'please'].group_by(&:size)
        #   #  => {4=>["test"], 2=>["me"], 6=>["please"]}
        #
        # - zverok, 2016-09-12
        @groups_by_pos = GroupBy.get_positions_group_map_for_df(@context, @group_vectors, sort: true)
      end

      # Get a Daru::Vector of the size of each group.
      def size
        index = get_grouped_index

        values = @groups_by_pos.values.map(&:size)
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
        indexes   = groups_by_idx[group]
        elements  = @context.each_vector.map(&:to_a)
        transpose = elements.transpose
        rows      = indexes.each.map { |idx| transpose[idx] }

        Daru::DataFrame.rows(
          rows, index: indexes, order: @context.vectors
        )
      end

      # Iteratively applies a function to the values in a group and accumulates the result.
      # @param init (nil) The initial value of the accumulator.
      # @yieldparam block [Proc] A proc or lambda that accepts two arguments.  The first argument
      #                          is the accumulated result.  The second argument is a DataFrame row.
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
        result_hash = groups_by_idx.each_with_object({}) do |(group, indices), h|
          group_indices = indices.map { |v| @context.index.to_a[v] }

          grouped_result = init
          group_indices.each do |idx|
            grouped_result = yield(grouped_result, @context.row[idx])
          end

          h[group] = grouped_result
        end

        index = get_grouped_index(result_hash.keys)

        Daru::Vector.new(result_hash.values, index: index)
      end

      def inspect
        grouped_df.inspect
      end

      # Function to use for aggregating the data.
      # `group_by` is using Daru::DataFrame#aggregate
      #
      # @param options [Hash] options for column, you want in resultant dataframe
      #
      # @return [Daru::DataFrame]
      #
      # @example
      #
      #   df = Daru::DataFrame.new(
      #     name: ['Ram','Krishna','Ram','Krishna','Krishna'],
      #     visited: ['Hyderabad', 'Delhi', 'Mumbai', 'Raipur', 'Banglore'])
      #
      #   => #<Daru::DataFrame(5x2)>
      #                   name   visited
      #            0       Ram Hyderabad
      #            1   Krishna     Delhi
      #            2       Ram    Mumbai
      #            3   Krishna    Raipur
      #            4   Krishna  Banglore
      #
      #   df.group_by(:name)
      #   => #<Daru::DataFrame(5x1)>
      #                          visited
      #      Krishna         1     Delhi
      #                      3    Raipur
      #                      4  Banglore
      #          Ram         0 Hyderabad
      #                      2    Mumbai
      #
      #   df.group_by(:name).aggregate(visited: -> (vec){vec.to_a.join(',')})
      #   => #<Daru::DataFrame(2x1)>
      #                  visited
      #       Krishna Delhi,Raipur,Banglore
      #           Ram Hyderabad,Mumbai
      #
      def aggregate(options={})
        new_index = get_grouped_index

        @context.aggregate(options) { [@groups_by_pos.values, new_index] }
      end

      private

      def select_groups_from method, quantity
        selection     = @context
        rows, indexes = [], []

        groups_by_idx.each_value do |index|
          index.send(method, quantity).each do |idx|
            rows << selection.row[idx].to_a
            indexes << idx
          end
        end
        indexes.flatten!

        Daru::DataFrame.rows(rows, order: @context.vectors, index: indexes)
      end

      def select_numeric_non_group_vectors
        @non_group_vectors.select { |ngvec| @context[ngvec].type == :numeric }
      end

      def apply_method method_type, method
        raise 'To implement' if method_type != :numeric
        aggregation_options = select_numeric_non_group_vectors.map { |k| [k, method] }.to_h

        aggregate(aggregation_options)
      end

      def get_grouped_index(index_tuples=nil)
        index_tuples = @groups_by_pos.keys if index_tuples.nil?

        if multi_indexed_grouping?
          Daru::MultiIndex.from_tuples(index_tuples)
        else
          Daru::Index.new(index_tuples.flatten)
        end
      end

      def multi_indexed_grouping?
        return false unless @groups_by_pos.keys[0]
        @groups_by_pos.keys[0].size > 1
      end
    end
  end
end
