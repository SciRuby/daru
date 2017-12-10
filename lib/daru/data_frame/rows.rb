module Daru
  class DataFrame
    class Rows
      class Proxy
        attr_reader :dataframe, :position

        extend Forwardable

        # TODO: Other methods
        def_delegators :to_vector, :[], :each, :select

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

        def inspect
          "#{dataframe}:row(#{position})"
        end

        def []=(label, value)
          column_pos = dataframe.vectors.pos(label)
          dataframe.data[column_pos].set_at([position], value)
        end

        def to_vector
          # TODO: in fact, not efficient. This way df.rows[foo][bar] should take just from one col,
          # but it takes from all cols, then constructs vector, then fetches one value from it.
          Vector.new(dataframe.data.map { |col| col.at(position) }, index: dataframe.vectors)
        end

        alias dup to_vector
      end

      def self.from_a(proxies)
        # TODO: validate types & same df
        new(proxies.first.dataframe, positions: proxies.map(&:position))
      end

      attr_reader :dataframe, :positions

      def initialize(dataframe, positions: nil)
        @dataframe = dataframe
        @positions = positions # TODO: limit to df.nrows
      end

      include IdempotentEnumerable
      idempotent_enumerable.constructor = :from_a

      def ==(other)
        other.is_a?(self.class) && dataframe.equal?(other.dataframe) && positions == other.positions
      end

      def inspect
        "#{dataframe}:rows#{inspect_positions}"
      end

      def count
        positions ? positions.count : dataframe.nrows
      end

      def at(position)
        Proxy.new(dataframe, position)
      end

      def fetch(label)
        at(dataframe.index.pos(label))
      end

      def slice(*labels)
        by_positions(dataframe.index.positions(*labels))
      end

      def slice_at(*poss)
        # TODO: we don't need to ask dataframe.index, just something like Util.positions_array(poss, count)
        real_poss = positions ? positions.values_at(*poss) : dataframe.index.positions_at(*poss)
        by_positions(real_poss)
      end

      # TODO: row index? Or just name to Proxy?
      def each
        return to_enum(:each) unless block_given?
        seq = positions || (0...count)
        seq.each { |pos| yield(Proxy.new(dataframe, pos)) }
      end

      def dup
        DataFrame.rows(map(&:dup), index: dataframe.index)
      end

      private

      def by_positions(poss)
        poss &= positions if positions
        self.class.new(dataframe, positions: poss)
      end

      def inspect_positions
        return '' unless positions
        res =
          case positions.count
          when 0
            'no'
          when 1..10
            "at #{positions.join(',')}"
          else
            "#{positions.count}"
          end
        "(#{res})"
      end
    end
  end
end
