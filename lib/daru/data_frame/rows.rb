module Daru
  class DataFrame
    class Rows
      class Proxy
        attr_reader :dataframe, :position

        def initialize(dataframe, position)
          @dataframe = dataframe
          @position = position
        end

        def data
          dataframe.data.map { |col| col.at(position) }
        end

        def index
          dataframe.vectors
        end

        def name
          dataframe.index.at(position)
        end

        def ==(other)
          case other
          when Proxy
            position == other.position && dataframe.equal?(other.dataframe) # EXACTLY the same DF
          when Vector
            data == other.data && index == other.index
          else
            false
          end
        end
      end

      attr_reader :dataframe

      def initialize(dataframe)
        @dataframe = dataframe
      end

      def count
        dataframe.nrows
      end

      def at(position)
        Proxy.new(dataframe, position)
      end

      def vector(label)
        at(dataframe.index.pos(label))
      end
    end
  end
end
