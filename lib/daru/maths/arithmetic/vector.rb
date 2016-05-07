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
          math_unary_op :exp
        end

        def sqrt
          math_unary_op :sqrt
        end

        def abs
          recode { |e| e.abs unless e.nil? }
        end

        def round precision=0
          recode { |e| e.round(precision) unless e.nil? }
        end

        private

        def math_unary_op operation
          recode { |e| Math.send(operation, e) unless e.nil? }
        end

        def binary_op operation, other
          case other
          when Daru::Vector
            v2v_binary operation, other
          else
            v2o_binary operation, other
          end
        end

        def v2o_binary operation, other
          Daru::Vector.new map { |e| e.nil? ? nil : e.send(operation, other) },
            name: @name, index: @index
        end

        def v2v_binary operation, other
          common_idxs = []
          elements    = []
          index = (@index.to_a | other.index.to_a).sort

          index.each do |idx|
            this = self.index.include?(idx) ? self[idx] : nil
            that = other.index.include?(idx) ? other[idx] : nil

            elements << (this && that ? this.send(operation, that) : nil)
            common_idxs << idx
          end

          Daru::Vector.new(elements, name: @name, index: common_idxs)
        end
      end
    end
  end
end
