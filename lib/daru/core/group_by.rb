module Daru
  module Core
    class GroupBy

      attr_reader :groups

      def initialize context, names
        @groups = {}
        vectors = names.map { |vec| context.vector[vec].to_a }
        tuples  = vectors[0].zip(*vectors[1..-1])
        keys    = tuples.uniq.sort

        keys.each do |key|
          @groups[key] = all_indices_for(tuples, key)
        end
      end

     private 

      def all_indices_for arry, element
        found, index, indexes = -1, -1, []
        while found
          found = arry[index+1..-1].index(element)
          if found
            index = index + found + 1
            indexes << index
          end
        end
        indexes
      end
    end
  end
end