module Daru
  module Core
    module MergeHelper
      class << self
        def resolve_duplicates df_hash1, df_hash2, on
        end

        def hashify df
          hsh = df1.to_hash
          hsh.each { |k,v| hsh[k] = v.to_a }
          hsh
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

          helper.resolve_duplicates df_hash1, df_hash2, opts[:on]
        end
      end
    end
  end
end
