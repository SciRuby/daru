module Daru
  module Core
    module Query
      class BoolArray
        attr_reader :barry

        def initialize barry
          @barry = barry
        end

        def & other
          BoolArray.new(@barry.zip(other.barry).map { |b, o| b && o })
        end

        alias :and :&

        def | other
          BoolArray.new(@barry.zip(other.barry).map { |b, o| b || o })
        end

        alias :or :|

        def !
          BoolArray.new(@barry.map(&:!))
        end

        def == other
          @barry == other.barry
        end

        def to_a
          @barry
        end

        def inspect
          "#<#{self.class}:#{object_id} bool_arry=#{@barry}>"
        end
      end

      class << self
        def apply_scalar_operator operator, data, other
          BoolArray.new(data.map { |d| !!d.send(operator, other) if d.respond_to?(operator) })
        end

        def apply_vector_operator operator, vector, other
          BoolArray.new(vector.zip(other).map { |d, o| !!d.send(operator, o) })
        end

        def df_where data_frame, bool_array
          vecs = data_frame.map do |vector|
            vector.where(bool_array)
          end

          Daru::DataFrame.new(
            vecs, order: data_frame.vectors, index: vecs[0].index, clone: false
          )
        end

        def vector_where dv, bool_array
          new_data, new_index = fetch_new_data_and_index dv, bool_array

          resultant_dv = Daru::Vector.new new_data,
            index: dv.index.class.new(new_index),
            dtype: dv.dtype,
            type: dv.type,
            name: dv.name

          # Preserve categories order for category vector
          resultant_dv.categories = dv.categories if dv.category?
          resultant_dv
        end

        private

        def fetch_new_data_and_index dv, bool_array
          barry = bool_array.to_a
          positions = dv.size.times.select { |i| barry[i] }
          # FIXME: The below 4 lines should be replaced with values_at when the
          # stack error is fixed in Ruby.
          # eg - new_data = dv.data.data.values_at(*positions)

          data = dv.type == :category ? dv.to_a : dv.data.data # non-cat optimize
          new_data = positions.map { |i| data[i] }

          idx = dv.index.to_a
          new_index = positions.map { |i| idx[i] }

          [new_data, new_index]
        end
      end
    end
  end
end
