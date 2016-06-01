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

          hsh =
            all_vectors.map do |vector_name|
              vector = dataframe_binary_operation_on_vectors other, vector_name, operation, all_indexes

              [vector_name, vector]
            end.to_h

          Daru::DataFrame.new(hsh, index: all_indexes, name: @name, dtype: @dtype)
        end

        def dataframe_binary_operation_on_vectors other, name, operation, indexes
          if has_vector?(name) && other.has_vector?(name)
            self[name].send(operation, other[name])
          else
            Daru::Vector.new([], index: indexes, name: name)
          end
        end

        def scalar_binary_operation operation, other
          dup.map_vectors! do |vector|
            vector.numeric? ? vector.send(operation, other) : vector
          end
        end
      end
    end
  end
end
