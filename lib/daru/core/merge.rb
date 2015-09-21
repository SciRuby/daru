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
          hsh = df.to_hash
          hsh.each { |k,v| hsh[k] = v.to_a }
          hsh
        end
        
        def arrayify df
          arr = df.to_a
          col_names = arr[0][0].keys
          values = arr[0].map{|h| h.values}

          return col_names, values
        end

        def inner_join df1, df2, on
          col_names1, table1 = arrayify df1
          col_names2, table2 = arrayify df2

          #resolve duplicates
          indicies1 = on.map{|i| col_names1.index(i)}
          indicies2 = on.map{|i| col_names2.index(i)}
          col_names2.map! do |name| 
            if (col_names1.include?(name))
              col_names1[col_names1.index(name)] = (name.to_s + "_1").to_sym unless on.include?(name)
              (name.to_s + "_2").to_sym
            else
              name
            end
          end

          #combine key columns to a single column value
          on_cols1 = table1.flat_map{|x| indicies1.map{|i| x[i].to_s}.join("+")}
          on_cols2 = table2.flat_map{|x| indicies2.map{|i| x[i].to_s}.join("+")}

          #parameters for a BF with approx 0.1% false positives
          m = on_cols2.size * 15
          k = 11

          bf = BloomFilter::Native.new({:size => m, :hashes => k, :bucket => 1})
          on_cols2.each{|x| bf.insert(x)}

          x_ind = -1
          joined_new = on_cols1.map do |x|
            x_ind+=1
            if (bf.include?(x))
              {x_ind => on_cols2.each_index.select{|y_ind| on_cols2[y_ind] == x}}
            else
              {x_ind => []}
            end
          end
            .reduce({}) {|h,pairs| pairs.each {|k,v| (h[k] ||= []) << v}; h}
            .map{|ind1, inds2| inds2.flatten.flat_map{|ind2| [table1[ind1], table2[ind2]].flatten} if inds2.flatten.size > 0}

          joined_cols = [col_names1, col_names2].flatten
          df = Daru::DataFrame.rows(joined_new.compact, order: joined_cols)
          on.each{|x| df.delete_vector (x.to_s + "_2").to_sym}

          df
        end

        def full_outer_join df1, df2, df_hash1, df_hash2, on
          left  = left_outer_join df1, df2, df_hash1, df_hash2, on, true
          right = right_outer_join df1, df2, df_hash1, df_hash2, on, true

          Daru::DataFrame.rows(
            (left.values.transpose | right.values.transpose), order: left.keys)
        end

        def left_outer_join df1, df2, df_hash1, df_hash2, on, as_hash=false
          joined_hash = {}
          ((df_hash1.keys - on) | on | (df_hash2.keys - on)).each do |k|
            joined_hash[k] = []
          end

          
          (0...df1.size).each do |id1|
            joined = false
            (0...df2.size).each do |id2|
              if on.all? { |n| df_hash1[n][id1] == df_hash2[n][id2] }
                joined = true
                joined_hash.each do |k,v|
                  v << (df_hash1.has_key?(k) ? df_hash1[k][id1] : df_hash2[k][id2])
                end
              end
            end

            unless joined
              df_hash1.keys.each do |k|
                joined_hash[k] << df_hash1[k][id1]
              end

              (joined_hash.keys - df_hash1.keys).each do |k|
                joined_hash[k] << nil
              end
              joined = false
            end
          end

          return joined_hash if as_hash
          Daru::DataFrame.new(joined_hash, order: joined_hash.keys)
        end

        def right_outer_join df1, df2, df_hash1, df_hash2, on, as_hash=false
          joined_hash = {}
          ((df_hash1.keys - on) | on | (df_hash2.keys - on)).each do |k|
            joined_hash[k] = []
          end

          (0...df2.size).each do |id1|
            joined = false
            (0...df1.size).each do |id2|
              if on.all? { |n| df_hash2[n][id1] == df_hash1[n][id2] }
                joined = true
                joined_hash.each do |k,v|
                  v << (df_hash2.has_key?(k) ? df_hash2[k][id1] : df_hash1[k][id2])
                end
              end
            end

            unless joined
              df_hash2.keys.each do |k|
                joined_hash[k] << df_hash2[k][id1]
              end

              (joined_hash.keys - df_hash2.keys).each do |k|
                joined_hash[k] << nil
              end
              joined = false
            end
          end

          return joined_hash if as_hash
          Daru::DataFrame.new(joined_hash, order: joined_hash.keys)
        end

        def verify_dataframes df_hash1, df_hash2, on
          raise ArgumentError, 
            "All fields in :on must be present in self" if !on.all? { |e| df_hash1[e] }
          raise ArgumentError,
            "All fields in :on must be present in other DF" if !on.all? { |e| df_hash2[e] }
        end
      end
    end
    # Private module containing methods for join, merge, concat operations on
    # dataframes and vectors.
    # @private
    module Merge
      class << self
        def join df1, df2, opts={}
          helper = MergeHelper

          df_hash1 = helper.hashify df1
          df_hash2 = helper.hashify df2
          on = opts[:on]

          helper.verify_dataframes df_hash1, df_hash2, on
          helper.resolve_duplicates df_hash1, df_hash2, on

          case opts[:how]
          when :inner
            helper.inner_join df1, df2, on
          when :outer
            helper.full_outer_join df1, df2, df_hash1, df_hash2, on
          when :left
            helper.left_outer_join df1, df2, df_hash1, df_hash2, on
          when :right
            helper.right_outer_join df1, df2, df_hash1, df_hash2, on
          else
            raise ArgumentError, "Unrecognized option in :how => #{opts[:how]}"
          end
        end
      end
    end
  end
end
