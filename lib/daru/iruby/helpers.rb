module Daru
  # @private
  module IRuby
    module Helpers
      module_function

      def tuples_with_rowspans(index)
        index.sparse_tuples.transpose
             .map { |r| nils_counted(r) }
             .transpose.map(&:compact)
      end

      def tuples_with_colspans(index)
        index.sparse_tuples.transpose
             .map { |r| nils_counted(r) }
             .map(&:compact)
      end

      # It is complicated, but the only algo I could think of.
      # It does [:a, nil, nil, :b, nil, :c] # =>
      #         [[:a,3], nil, nil, [:b,2], nil, :c]
      # Needed by tuples_with_colspans/rowspans, which we need for pretty HTML
      def nils_counted array
        grouped = [[array.first]]
        array[1..-1].each do |val|
          if val
            grouped << [val]
          else
            grouped.last << val
          end
        end
        grouped.flat_map { |items|
          [[items.first, items.count], *[nil] * (items.count - 1)]
        }
      end
    end
  end
end
