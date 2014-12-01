module Daru
  module Maths
    module Arithmetic
      module Vector
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

        def exp
          # TODO
        end

        def sqrt
          # TODO
        end

        def round
          # TODO
        end

       private

        def binary_op operation, other
          case other
          when Daru::Vector
            v2v_binary operation, other
          else
            v2o_binary operation, other
          end
        end

        def v2o_binary operation, other
          Daru::Vector.new self.map { |e| e.send(operation, other) }, name: @name, index: @index
        end

        def v2v_binary operation, other
          common_idxs = []
          elements    = []

          @index.each do |idx|
            this = self[idx]
            that = other[idx]

            if this and that
              elements << this.send(operation ,that)
              common_idxs << idx
            end
          end

          Daru::Vector.new(elements, name: @name, index: common_idxs)
        end
      end
    end
  end
end