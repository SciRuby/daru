module Daru
  module Core
    module Query
      class BoolArray
        attr_reader :barry

        def initialize barry
          @barry = barry
        end

        def & other
          BoolArray.new @barry.zip(other.barry).map { |b, o| b && o }
        end

        alias :and :&

        def | other
          BoolArray.new @barry.zip(other.barry).map { |b, o| b || o }
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
          BoolArray.new data.map { |d| !!d.send(operator, other) }
        end

        def apply_vector_operator operator, vector, other
          BoolArray.new vector.zip(other).map { |d, o| !!d.send(operator, o) }
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
          data = dv.to_a
          new_data = []
          new_index = []
          bool_array.to_a.each_with_index do |b, i|
            if b
              new_data << data[i]
              new_index << dv.index.at(i)
            end
          end
          
          resultant_dv = Daru::Vector.new new_data,
            index: dv.index.class.new(new_index),
            dtype: dv.dtype,
            type: dv.type,
            name: dv.name

          # Preserve categories order for category vector
          if dv.type == :category
            resultant_dv.categories = dv.categories
            # TODO: Remove below line and make categories= return self
            resultant_dv
          else
            resultant_dv
          end
        end        
      end
    end
  end
end
