module Daru
  module Core
    class MergeFrame
      class NilSorter
        include Comparable

        def nil?
          true
        end

        def ==(_other)
          false
        end

        def <=>(other)
          other.nil? ? 0 : -1
        end
      end

      def initialize left_df, right_df, opts={}
        @on = opts[:on]
        @keep_left, @keep_right = extract_left_right(opts[:how])

        validate_on!(left_df, right_df)

        key_sanitizer = ->(h) { sanitize_merge_keys(h.values_at(*on)) }

        @left = df_to_a(left_df)
        @left.sort_by!(&key_sanitizer)
        @left_key_values = @left.map(&key_sanitizer)

        @right = df_to_a(right_df)
        @right.sort_by!(&key_sanitizer)
        @right_key_values = @right.map(&key_sanitizer)

        @left_keys, @right_keys = merge_keys(left_df, right_df, on)
      end

      def join
        res = []

        until left.empty? && right.empty?
          lkey = first_left_key
          rkey = first_right_key

          row(lkey, rkey).tap { |r| res << r if r }
        end

        Daru::DataFrame.new(res, order: left_keys.values + on + right_keys.values)
      end

      private

      attr_reader :on,
        :left, :left_key_values, :keep_left, :left_keys,
        :right, :right_key_values, :keep_right, :right_keys

      attr_accessor :merge_key

      LEFT_RIGHT_COMBINATIONS = {
        #       left   right
        inner: [false, false],
        left:  [true, false],
        right: [false, true],
        outer: [true, true]
      }.freeze

      def extract_left_right(how)
        LEFT_RIGHT_COMBINATIONS[how] or
          raise ArgumentError, "Unrecognized join option: #{how}"
      end

      def sanitize_merge_keys(merge_keys)
        merge_keys.map { |v| v || NilSorter.new }
      end

      def df_to_a df
        # FIXME: much faster than "native" DataFrame#to_a. Should not be
        h = df.to_h
        keys = h.keys
        h.values.map(&:to_a).transpose.map { |r| keys.zip(r).to_h }
      end

      def merge_keys(df1, df2, on)
        duplicates =
          (df1.vectors.to_a + df2.vectors.to_a - on)
          .group_by(&:itself)
          .select { |_, g| g.count == 2 }.map(&:first)

        [
          guard_keys(df1.vectors.to_a - on, duplicates, 1),
          guard_keys(df2.vectors.to_a - on, duplicates, 2)
        ]
      end

      def guard_keys keys, duplicates, num
        keys.map { |v| [v, guard_duplicate(v, duplicates, num)] }.to_h
      end

      def guard_duplicate val, duplicates, num
        duplicates.include?(val) ? :"#{val}_#{num}" : val
      end

      def row(lkey, rkey)
        case
        when !lkey && !rkey
          # :nocov:
          # It's just an impossibility handler, can't be covered :)
          raise 'Unexpected condition met during merge'
          # :nocov:
        when lkey == rkey
          self.merge_key = lkey
          merge_matching_rows
        when !rkey || lt(lkey, rkey)
          left_row_missing_right
        else # !lkey || lt(rkey, lkey)
          right_row_missing_left
        end
      end

      def merge_matching_rows
        if one_to_one_merge?
          merge_rows(one_to_one_left_row, one_to_one_right_row)
        elsif one_to_many_merge?
          merge_rows(one_to_many_left_row, one_to_many_right_row)
        else
          result = cartesian_product.shift
          end_cartesian_product if cartesian_product.empty?
          result
        end
      end

      def one_to_one_merge?
        merge_key != next_left_key && merge_key != next_right_key
      end

      def one_to_many_merge?
        !(merge_key == next_left_key && merge_key == next_right_key)
      end

      def one_to_one_left_row
        left_key_values.shift
        left.shift
      end

      def one_to_many_left_row
        if next_right_key && first_right_key == next_right_key
          left.first
        else
          left_key_values.shift
          left.shift
        end
      end

      def one_to_one_right_row
        right_key_values.shift
        right.shift
      end

      def one_to_many_right_row
        if next_left_key && first_left_key == next_left_key
          right.first
        else
          right_key_values.shift
          right.shift
        end
      end

      def left_row_missing_right
        val = one_to_one_left_row
        expand_row(val, left_keys) if keep_left
      end

      def right_row_missing_left
        val = one_to_one_right_row
        expand_row(val, right_keys) if keep_right
      end

      def lt(k1, k2)
        (k1 <=> k2) == -1
      end

      def merge_rows lrow, rrow
        left_keys
          .map { |from, to| [to, lrow[from]] }.to_h
          .merge(on.map { |col| [col, lrow[col]] }.to_h)
          .merge(right_keys.map { |from, to| [to, rrow[from]] }.to_h)
      end

      def expand_row row, renamings
        renamings
          .map { |from, to| [to, row[from]] }.to_h
          .merge(on.map { |col| [col, row[col]] }.to_h)
      end

      def first_right_key
        right_key_values.empty? ? nil : right_key_values.first
      end

      def next_right_key
        right_key_values.size <= 1 ? nil : right_key_values[1]
      end

      def first_left_key
        left_key_values.empty? ? nil : left_key_values.first
      end

      def next_left_key
        left_key_values.size <= 1 ? nil : left_key_values[1]
      end

      def left_rows_at_merge_key
        left.take_while { |arr| sanitize_merge_keys(arr.values_at(*on)) == merge_key }
      end

      def right_rows_at_merge_key
        right.take_while { |arr| sanitize_merge_keys(arr.values_at(*on)) == merge_key }
      end

      def cartesian_product
        @cartesian_product ||= left_rows_at_merge_key.product(right_rows_at_merge_key).map do |left_row, right_row|
          merge_rows(left_row, right_row)
        end
      end

      def end_cartesian_product
        left_size = left_rows_at_merge_key.size
        left_key_values.shift(left_size)
        left.shift(left_size)

        right_size = right_rows_at_merge_key.size
        right_key_values.shift(right_size)
        right.shift(right_size)
        @cartesian_product = nil
      end

      def validate_on!(left_df, right_df)
        @on.each do |on|
          left_df.has_vector?(on) && right_df.has_vector?(on) or
            raise ArgumentError, "Both dataframes expected to have #{on.inspect} field"
        end
      end
    end

    module Merge
      class << self
        def join df1, df2, opts={}
          MergeFrame.new(df1, df2, opts).join
        end
      end
    end
  end
end
