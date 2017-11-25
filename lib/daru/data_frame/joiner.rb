module Daru
  class DataFrame
    # @private
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

      def join
        rows =
          @row_map
          .select { |_, val| yield(val) }
          .map { |join_value, row|
            [
              columns.zip(join_value).to_h,
              hashes_from(row[:left], left_df, @left_columns),
              hashes_from(row[:right], right_df, @right_columns)
            ]
          }
          .flat_map(&method(:join_one))

        Daru::DataFrame.new(rows, order: joined_columns)
      end

      def join_one((between, from_left, from_right)) # TWO pairs of brackets is for args deconstruction!
        if from_left.any? && from_right.any?
          from_left.product(from_right).map { |l, r| l.merge(between).merge(r) }
        elsif from_left.any?
          from_left.map { |l| l.merge(between) }
        elsif from_right.any?
          from_right.map { |r| between.merge(r) }
        end
      end

      def hashes_from(rows, df, columns)
        rows.map { |idx|
          row = df.row.at(idx)
          columns.keys.zip(row.values_at(*columns.values)).to_h
        }
      end

      def setup_join_map
        setup_row_map
        setup_column_map
      end

      def setup_row_map
        @row_map = Hash.new { |h, k| h[k] = {left: [], right: []} }
        left_df[*columns].to_df.each_row_with_index do |row, i|
          @row_map[row.data][:left] << i
        end

        right_df[*columns].to_df.each_row_with_index do |row, i|
          @row_map[row.data][:right] << i
        end
      end

      # rubocop:disable Metrics/AbcSize
      # Both methods a bit above our current limit.
      # And both look too complicated indeed, should be rethouhgt.
      def setup_column_map
        @left_columns =
          left_df
          .vectors.to_a.select { |col| rename_map.key?(col) }
          .map.with_index { |col, i| [rename_map[col][:left], i] }.to_h
        @right_columns =
          right_df
          .vectors.to_a.select { |col| rename_map.key?(col) }
          .map.with_index { |col, i| [rename_map[col][:right], i] }.to_h
      end

      def rename_map
        @rename_map ||=
          (left_df.vectors.to_a + right_df.vectors.to_a - columns)
          .group_by(&:itself)
          .map { |col, group|
            [col, {
              left: group.count == 1 ? col : "#{left_df.name}.#{col}",
              right: group.count == 1 ? col : "#{right_df.name}.#{col}"
            }]
          }.to_h
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
