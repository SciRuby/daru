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

        def inner_join df1, df2, df_hash1, df_hash2, on
          joined_hash = {}
          ((df_hash1.keys - on) | on | (df_hash2.keys - on)).each do |k|
            joined_hash[k] = []
          end

          (0...df1.size).each do |id1|
            (0...df2.size).each do |id2|
              if on.all? { |n| df_hash1[n][id1] == df_hash2[n][id2] }
                joined_hash.each do |k,v|
                  v << (df_hash1.has_key?(k) ? df_hash1[k][id1] : df_hash2[k][id2])
                end
              end
            end
          end

          Daru::DataFrame.new(joined_hash, order: joined_hash.keys)
        end

        def full_outer_join df1, df2, df_hash1, df_hash2, on
          
        end

        def left_outer_join df1, df2, df_hash1, df_hash2, on
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

          Daru::DataFrame.new(joined_hash, order: joined_hash.keys)
        end

        def right_outer_join df1, df2, df_hash1, df_hash2, on
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
            helper.inner_join df1, df2, df_hash1, df_hash2, on
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
