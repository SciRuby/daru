module Daru
  module Core
    module Query
      class << self
        def apply_scalar_operator operator, data, other
          data.inject([]) do |memo,d|
            memo << (d.send(operator, other) ? true : false)
            memo
          end
        end

        def apply_vector_operator operator, vector, other
          bool_arry = []
          vector.each_with_index do |d, i|
            bool_arry << (d.send(operator, other[i]) ? true : false)
          end

          bool_arry
        end

        def df_where bool_array
          
        end

        def vector_where data, bool_array
          
        end
      end
    end
  end
end