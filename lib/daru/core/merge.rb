module Daru
  module Core
    module MergeHelper
      class << self
        def replace_keys_if_duplicates hash, matcher
          matched = nil
          hash.keys.each { |d|
            if matcher.match(Regexp.new(d.to_s))
              matched = d
              break
            end
          }

          if matched
            hash[matcher] = hash[matched]
            hash.delete matched
          end
        end

        def resolve_duplicates df_hash1, df_hash2, on
          hk = df_hash1.keys + df_hash2.keys - on
          recoded = hk.recode_repeated.map(&:to_sym)
          diff = (recoded - hk).sort

          diff.each_slice(2) do |a|
            replace_keys_if_duplicates df_hash1, a[0]
            replace_keys_if_duplicates df_hash2, a[1]
          end
        end

        def hashify df
          hsh = df.to_h
          hsh.each { |k,v| hsh[k] = v.to_a }
          hsh
        end

        def arrayify df
          arr = df.to_a
          col_names = arr[0][0].keys
          values = arr[0].map{|h| h.values}

          return col_names, values
        end

        def arrayify_with_sort_keys(size, df_hash, on)

          # Converting to a hash and then to an array is more complex
          # than using df.to_a or df.map(:row).  However, it's
          # substantially faster this way.

          idx_keys = on.map { |key| df_hash.keys.index(key) }

          (0...size).reduce([]) do |r, idx|
            key_values = on.map { |col| df_hash[col][idx] }
            row_values = df_hash.map { |col, val| val[idx] }
            r << [key_values, row_values]
          end

          # Conceptually simpler and does the same thing, but slows down the
          # total merge algorithm by 2x.  Would be nice to improve the performance
          # of df.map(:row)
  #        df.map(:row) do |row|
  #          key_values = on.map { |key| row[key] }
  #          [key_values, row.to_a]
  #        end
        end

        def verify_dataframes df_hash1, df_hash2, on
          raise ArgumentError,
            "All fields in :on must be present in self" if !on.all? { |e| df_hash1[e] }
          raise ArgumentError,
            "All fields in :on must be present in other DF" if !on.all? { |e| df_hash2[e] }
        end
      end
    end



    class MergeFrame

      def initialize(df1, df2, on: nil)
        @df1 = df1
        @df2 = df2
        @on = on
      end

      def inner opts
        merge_join(left: false, right: false)
      end

      def left opts
        merge_join(left: true, right: false)
      end

      def right opts
        merge_join(left: false, right: true)
      end

      def outer opts
        merge_join(left: true, right: true)
      end

      def merge_join(left: true, right: true)

        MergeHelper.verify_dataframes df1_hash, df2_hash, @on
        MergeHelper.resolve_duplicates df1_hash, df2_hash, @on

        # TODO: Use native dataframe sorting.
        #  It would be ideal to reuse sorting functionality that is native
        #  to dataframes.  Unfortunately, native dataframe sort introduces
        #  an overhead that reduces join performance by a factor of 4!  Until
        #  that aspect is improved, we resort to a simpler array sort.
        df1_array.sort_by! { |row| [row[0].nil? ? 0 : 1, row[0]] }
        df2_array.sort_by! { |row| [row[0].nil? ? 0 : 1, row[0]] }

        idx1 = 0
        idx2 = 0

        merged = []
        while (idx1 < @df1.size || idx2 < @df2.size) do

          key1 = df1_array[idx1][0] if idx1 < @df1.size
          key2 = df2_array[idx2][0] if idx2 < @df2.size

          if key1 == key2 && idx1 < @df1.size && idx2 < @df2.size
            idx2_start = idx2

            while (idx2 < @df2.size) && (df1_array[idx1][0] == df2_array[idx2][0]) do
              add_merge_row_to_hash([df1_array[idx1], df2_array[idx2]], joined_hash)
              idx2 += 1
            end

            idx2 = idx2_start if idx1+1 < @df1.size && df1_array[idx1][0] == df1_array[idx1+1][0]
            idx1 += 1
          elsif ([key1, key2].sort == [key1, key2] && idx1 < @df1.size) || idx2 == @df2.size
            add_merge_row_to_hash([df1_array[idx1], nil], joined_hash) if left
            idx1 += 1
          elsif idx2 < @df2.size || idx1 == @df1.size
            add_merge_row_to_hash([nil, df2_array[idx2]], joined_hash) if right
            idx2 += 1
          else
            raise 'Unexpected condition met during merge'
          end
        end

        Daru::DataFrame.new(joined_hash, order: joined_hash.keys)
      end



      private


      def joined_hash
        return @joined_hash if @joined_hash
        @joined_hash ||= {}

        ((df1_keys - @on) | @on | (df2_keys - @on)).each do |k|
          @joined_hash[k] = []
        end

        @joined_hash
      end

      def df1_hash
        @df1_hash ||= MergeHelper.hashify @df1
      end

      def df2_hash
        @df2_hash ||= MergeHelper.hashify @df2
      end

      def df1_array
        @df1_array ||= MergeHelper.arrayify_with_sort_keys @df1.size, df1_hash, @on
      end

      def df2_array
        @df2_array ||= MergeHelper.arrayify_with_sort_keys @df2.size, df2_hash, @on
      end

      def df1_keys
        df1_hash.keys
      end

      def df2_keys
        df2_hash.keys
      end

      # Private: The merge row contains two elements, the first is the row from the
      # first dataframe, the second is the row from the second dataframe.
      def add_merge_row_to_hash row, hash
        @df1_key_to_index ||= df1_keys.each_with_index.map { |k,idx| [k, idx] }.to_h
        @df2_key_to_index ||= df2_keys.each_with_index.map { |k,idx| [k, idx] }.to_h

        hash.each do |k,v|
          v ||= []

          left  = df1_keys.include?(k) ? row[0] && row[0][1][@df1_key_to_index[k]] : nil
          right = df2_keys.include?(k) ? row[1] && row[1][1][@df2_key_to_index[k]] : nil

          v << (left || right)
        end
      end
    end


    # Private module containing methods for join, merge, concat operations on
    # dataframes and vectors.
    # @private
    module Merge
      class << self
        def join df1, df2, opts={}
          on = opts[:on]

          mf = MergeFrame.new df1, df2, on: on
          mf.send opts[:how], {}
        end
      end
    end
  end
end
