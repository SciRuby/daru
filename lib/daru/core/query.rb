module Daru
  module Core
    module Query
      class BoolArray
        attr_reader :barry

        def initialize barry
          @barry = barry
        end

        def & other
          new_bool = []
          other_barry = other.barry
          @barry.each_with_index do |b, i|
            new_bool << (b and other_barry[i])
          end

          BoolArray.new(new_bool)
        end

        alias :and :&

        def | other
          new_bool = []
          other_barry = other.barry
          @barry.each_with_index do |b, i|
            new_bool << (b or other_barry[i])
          end

          BoolArray.new(new_bool)
        end

        alias :or :|

        def !
          BoolArray.new(@barry.map { |b| !b })
        end

        def == other
          @barry == other.barry
        end

        def to_a
          @barry
        end

        def inspect
          "(#{self.class}:#{self.object_id} bool_arry=#{@barry})"
        end
      end

      class << self
        def apply_scalar_operator operator, data, other
          arry = data.inject([]) do |memo,d|
            memo << (d.send(operator, other) ? true : false)
            memo
          end

          BoolArray.new(arry)
        end

        def apply_vector_operator operator, vector, other
          bool_arry = []
          vector.each_with_index do |d, i|
            bool_arry << (d.send(operator, other[i]) ? true : false)
          end

          BoolArray.new(bool_arry)
        end

        def df_where data_frame, bool_array
          vecs = data_frame.map do |vector|
            vector.where(bool_array)
          end

          Daru::DataFrame.new(
            vecs, order: data_frame.vectors, index: vecs[0].index, clone: false)
        end

        def vector_where data, index, bool_array, dtype
          new_data = []
          new_index = []
          bool_array.to_a.each_with_index do |b, i|
            if b
              new_data << data[i]
              new_index << index[i]
            end
          end

          Daru::Vector.new(new_data, index: new_index, dtype: dtype)
        end
      end
    end
  end
end