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

        def add_skipnil other
          index = (@index.to_a | other.index.to_a)
          elements = index.map do |idx|
            this = self.index.include?(idx) ? self[idx] : nil
            that = other.index.include?(idx) ? other[idx] : nil
            this = 0 if this.nil?
            that = 0 if that.nil?
            this && that ? this + that : nil
          end
          Daru::Vector.new(elements, name: @name, index: index)
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
          # FIXME: why the sorting?.. - zverok, 2016-05-18
          index = (@index.to_a | other.index.to_a).sort

          elements = index.map do |idx|
            this = self.index.include?(idx) ? self[idx] : nil
            that = other.index.include?(idx) ? other[idx] : nil

            this && that ? this.send(operation, that) : nil
          end

          Daru::Vector.new(elements, name: @name, index: index)
        end
      end
    end
  end
end
