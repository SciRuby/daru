module Daru
  class DataFrame
    class Joiner
      attr_reader :left_df, :right_df, :columns, :row_map

      def initialize(left_df, right_df, columns)
        @left_df = left_df
        @right_df = right_df
        @columns = Array(columns)
        setup_join_map
      end

      def join_values
        @row_map.keys
      end

      def joined_columns
        @left_columns.keys + columns + @right_columns.keys
      end

      def inner
        join { |row| row[:left].any? && row[:right].any? }
      end

      def left
        join { |row| row[:left].any? }
      end

      def right
        join { |row| row[:right].any? }
      end

      def outer
        join { true } # join everything
      end

      private

      def join(&row_filter)
        rows = @row_map.select { |_, val| row_filter.call(val) }
          .map { |join_value, row|
            [
              columns.zip(join_value).to_h,
              row[:left].map { |i| hash_from(i, left_df, @left_columns) },
              row[:right].map { |i| hash_from(i, right_df, @right_columns) }
            ]
          }
          .flat_map { |between, from_left, from_right|
            if from_left.any? && from_right.any?
              from_left.product(from_right).map { |l, r| l.merge(between).merge(r) }
            elsif from_left.any?
              from_left.map { |l| l.merge(between) }
            elsif from_right.any?
              from_right.map { |r| between.merge(r) }
            end
          }

        Daru::DataFrame.new(rows, order: joined_columns)
      end

      def hash_from(idx, df, columns)
        row = df.row.at(idx)
        columns.keys.zip(row.values_at(*columns.values)).to_h
      end

      def setup_join_map
        @row_map = Hash.new { |h, k| h[k] = {left: [], right: []} }
        left_df[*columns].to_df.each_row_with_index do |row, i|
          @row_map[row.data][:left] << i
        end

        right_df[*columns].to_df.each_row_with_index do |row, i|
          @row_map[row.data][:right] << i
        end

        rename_map = (left_df.vectors.to_a + right_df.vectors.to_a - columns).group_by(&:itself)
          .map { |col, group|
            [col, {
              left: group.count == 1 ? col : "#{left_df.name}.#{col}",
              right: group.count == 1 ? col : "#{right_df.name}.#{col}",
            }]
          }.to_h
        @left_columns = left_df.vectors.to_a.select { |col| rename_map.key?(col) }
          .map.with_index { |col, i| [rename_map[col][:left], i] }.to_h
        @right_columns = right_df.vectors.to_a.select { |col| rename_map.key?(col) }
          .map.with_index { |col, i| [rename_map[col][:right], i] }.to_h
      end
    end
  end
end
