module Daru
  module Maths
    # Module encapsulating all aritmetic methods on DataFrame.
    module Arithmetic
      module DataFrame    
        def + other
          binary_op :+, other
        end

        def - other
          binary_op :-, other
        end

        def * other
          binary_op :*, other
        end

        def / other
          binary_op :/, other
        end

        def % other
          binary_op :%, other
        end

        def ** other
          binary_op :**, other
        end

       private

        def binary_op operation, other
          clone = self.dup
          clone.map_vectors! do |vector|
            vector = vector.send(operation, other) if vector.type == :numeric
            vector
          end

          clone
        end
      end
    end
  end
end