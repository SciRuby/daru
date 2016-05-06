module Daru
  module Maths
    # Module encapsulating all aritmetic methods on DataFrame.
    module Arithmetic
      module DataFrame
        # Add a scalar or another DataFrame
        def + other
          binary_operation :+, other
        end

        # Subtract a scalar or another DataFrame.
        def - other
          binary_operation :-, other
        end

        # Multiply a scalar or another DataFrame.
        def * other
          binary_operation :*, other
        end

        # Divide a scalar or another DataFrame.
        def / other
          binary_operation :/, other
        end

        # Modulus with a scalar or another DataFrame.
        def % other
          binary_operation :%, other
        end

        # Exponent with a scalar or another DataFrame.
        def ** other
          binary_operation :**, other
        end

        # Calculate exponenential of all vectors with numeric values.
        def exp
          only_numerics(clone: false).recode(&:exp)
        end

        # Calcuate square root of numeric vectors.
        def sqrt
          only_numerics(clone: false).recode(&:sqrt)
        end

        def round precision=0
          only_numerics(clone: false).recode { |v| v.round(precision) }
        end

        private

        def binary_operation operation, other
          case other
          when Daru::DataFrame
            dataframe_binary_operation operation, other
          else
            scalar_binary_operation operation, other
          end
        end

        def dataframe_binary_operation operation, other
          all_vectors = (vectors.to_a | other.vectors.to_a).sort
          all_indexes = (index.to_a   | other.index.to_a).sort

          hsh = {}
          all_vectors.each do |vector_name|
            this = has_vector?(vector_name) ? self[vector_name] : nil
            that = other.has_vector?(vector_name) ? other[vector_name] : nil

            hsh[vector_name] =
              if this && that
                this.send(operation, that)
              else
                Daru::Vector.new([], index: all_indexes, name: vector_name)
              end
          end

          Daru::DataFrame.new(hsh, index: all_indexes, name: @name, dtype: @dtype)
        end

        def scalar_binary_operation operation, other
          clone = dup
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
