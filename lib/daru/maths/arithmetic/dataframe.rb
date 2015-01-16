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
          self.dup.map_vectors! { |v| v.exp if v.type == :numeric }
        end

        def sqrt
          self.dup.map_vectors! { |v| v.sqrt if v.type == :numeric }
        end

        def round precision=0
          self.dup.map_vectors! { |v| v.round(precision) if v.type == :numeric }
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
          all_vectors = (self.vectors.to_a | other.vectors.to_a).sort
          all_indexes = (self.index.to_a   | other.index.to_a).sort

          hsh = {}
          all_vectors.each do |vector_name|
            this = self .has_vector?(vector_name) ? self .vector[vector_name] : nil
            that = other.has_vector?(vector_name) ? other.vector[vector_name] : nil

            if this and that
              hsh[vector_name] = this.send(operation, that)
            else
              hsh[vector_name] = Daru::Vector.new([], index: all_indexes, 
                name: vector_name)
            end
          end

          Daru::DataFrame.new(hsh, index: all_indexes, name: @name, dtype: @dtype)          
        end

        def scalar_binary_operation operation, other
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