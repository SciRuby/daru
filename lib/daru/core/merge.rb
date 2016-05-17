module Daru
  module Core
    class MergeFrame
      def initialize left_df, right_df, opts={}
        @on = opts[:on]
        @keep_left, @keep_right = extract_left_right(opts[:how])

        @left  = df_to_a(left_df).sort_by { |h| h[on.first] }
        @right = df_to_a(right_df).sort_by { |h| h[on.first] }

        @left_keys, @right_keys = merge_keys(left_df, right_df, on)
      end

      def join
        res = []

        until left.empty? && right.empty?
          lkey = first_key(left)
          rkey = first_key(right)

          row(lkey, rkey).tap { |r| res << r if r }
        end

        Daru::DataFrame.new(res, order: left_keys.values + on + right_keys.values)
      end

      private

      attr_reader :on,
        :left, :keep_left, :left_keys,
        :right, :keep_right, :right_keys

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
        if lkey == rkey
          merge_rows(left.shift, right.shift)
        elsif !rkey || lkey && lt(lkey, rkey)
          left_row
        elsif !lkey || lt(rkey, lkey)
          right_row
        else
          raise 'Unexpected condition met during merge'
        end
      end

      def left_row
        val = left.shift
        expand_row(val, left_keys) if keep_left
      end

      def right_row
        val = right.shift
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

      def first_key(arr)
        arr.empty? ? nil : arr.first[on.first]
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
