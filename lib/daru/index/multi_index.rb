module Daru
  class MultiIndex < Index # rubocop:disable Metrics/ClassLength
    def each(&block)
      to_a.each(&block)
    end

    def map(&block)
      to_a.map(&block)
    end

    attr_reader :labels
    attr_reader :name

    def levels
      @levels.map(&:keys)
    end

    # names and levels should be of same size. If size of Array `name` is less
    # or greater than size of array `levels` then it raises `SizeError`.
    # If user don't want to put name for particular level then user must put
    # empty string in that index of Array `name`.
    # For example there is multi_index of 3 levels and user don't want to name
    # level 0, then do multi_index.name = ['', 'level1_name1', 'level2_name']
    #
    # @example
    #
    #   # set the name during initialization
    #
    #   mi = Daru::MultiIndex.new(
    #       levels: [[:a,:b,:c], [:one, :two]],
    #       labels: [[0,0,1,1,2,2], [0,1,0,1,0,1]], name: ['s1', 's2'])
    #
    #   # =>
    #   # <Daru::MultiIndex(6x2)>
    #   #   s1  s2
    #   #    a one
    #   #      two
    #   #    b one
    #   #      two
    #   #    c one
    #   #      two
    #
    #   # set new name
    #
    #   mi.name = ['k1', 'k2']
    #   => ["k1", "k2"]
    #
    #   mi
    #   =>
    #   #   #<Daru::MultiIndex(6x2)>
    #   #   k1  k2
    #   #    a one
    #   #      two
    #   #    b one
    #   #      two
    #   #    c one
    #   #      two
    #
    #   # access the name
    #
    #   mi.name
    #   => ["k1", "k2"]
    #
    #   # If you don't want to name level 0
    #
    #   mi.name = ['', 'k2']
    #   => ["", "k2"]
    #
    #   mi
    #   =>
    #   #<Daru::MultiIndex(6x2)>
    #   #       k2
    #   #    a one
    #   #      two
    #   #    b one
    #   #      two
    #   #    c one
    #   #      two
    #
    def initialize opts={}
      labels = opts[:labels]
      levels = opts[:levels]

      raise ArgumentError, 'Must specify both labels and levels' unless labels && levels
      raise ArgumentError, 'Labels and levels should be same size' if labels.size != levels.size
      raise ArgumentError, 'Incorrect labels and levels' if incorrect_fields?(labels, levels)

      @labels = labels
      @levels = levels.map { |e| e.map.with_index.to_h }
      self.name = opts[:name] unless opts[:name].nil?
    end

    def name=(names)
      validate_name names, @labels
      @name = names
    end

    def incorrect_fields?(_labels, levels)
      levels[0].size # FIXME: without this exact call some specs are failing

      levels.any? { |e| e.uniq.size != e.size }
    end

    private :incorrect_fields?

    def self.from_arrays arrays
      levels = arrays.map { |e| e.uniq.sort_by(&:to_s) }

      labels = arrays.each_with_index.map do |arry, level_index|
        level = levels[level_index]
        arry.map { |lvl| level.index(lvl) }
      end

      MultiIndex.new labels: labels, levels: levels
    end

    def self.from_tuples tuples
      from_arrays tuples.transpose
    end

    def self.try_from_tuples tuples
      if tuples.respond_to?(:first) && tuples.first.is_a?(Array)
        from_tuples(tuples)
      else
        nil
      end
    end

    def [] *key
      key.flatten!
      case
      when key[0].is_a?(Range)
        retrieve_from_range(key[0])
      when key[0].is_a?(Integer) && key.size == 1
        try_retrieve_from_integer(key[0])
      else
        begin
          retrieve_from_tuples key
        rescue NoMethodError
          raise IndexError, "Specified index #{key.inspect} do not exist"
        end
      end
    end

    def valid? *indexes
      # FIXME: This is perhaps not a good method
      pos(*indexes)
      return true
    rescue IndexError
      return false
    end

    # Returns positions given indexes or positions
    # @note If the arugent is both a valid index and a valid position,
    #   it will treated as valid index
    # @param indexes [Array<object>] indexes or positions
    # @example
    #   idx = Daru::MultiIndex.from_tuples [[:a, :one], [:a, :two], [:b, :one], [:b, :two]]
    #   idx.pos :a
    #   # => [0, 1]
    def pos *indexes
      if indexes.first.is_a? Integer
        return indexes.first if indexes.size == 1
        return indexes
      end
      res = self[indexes]
      return res if res.is_a? Integer
      res.map { |i| self[i] }
    end

    def subset *indexes
      if indexes.first.is_a? Integer
        MultiIndex.from_tuples(indexes.map { |index| key(index) })
      else
        self[indexes].conform indexes
      end
    end

    # Takes positional values and returns subset of the self
    #   capturing the indexes at mentioned positions
    # @param positions [Array<Integer>] positional values
    # @return [object] index object
    # @example
    #   idx = Daru::MultiIndex.from_tuples [[:a, :one], [:a, :two], [:b, :one], [:b, :two]]
    #   idx.at 0, 1
    #   # => #<Daru::MultiIndex(2x2)>
    #   #   a one
    #   #     two
    def at *positions
      positions = preprocess_positions(*positions)
      validate_positions(*positions)
      if positions.is_a? Integer
        key(positions)
      else
        Daru::MultiIndex.from_tuples positions.map(&method(:key))
      end
    end

    def add *indexes
      Daru::MultiIndex.from_tuples(to_a + [indexes])
    end

    def reorder(new_order)
      from = to_a
      MultiIndex.from_tuples(new_order.map { |i| from[i] })
    end

    def try_retrieve_from_integer int
      @levels[0].key?(int) ? retrieve_from_tuples([int]) : int
    end

    def retrieve_from_range range
      MultiIndex.from_tuples(range.map { |index| key(index) })
    end

    def retrieve_from_tuples key
      chosen = []

      key.each_with_index do |k, depth|
        level_index = @levels[depth][k]
        raise IndexError, "Specified index #{key.inspect} do not exist" if level_index.nil?
        label = @labels[depth]
        chosen = find_all_indexes label, level_index, chosen
      end

      return chosen[0] if chosen.size == 1 && key.size == @levels.size
      multi_index_from_multiple_selections(chosen)
    end

    def multi_index_from_multiple_selections chosen
      MultiIndex.from_tuples(chosen.map { |e| key(e) })
    end

    def find_all_indexes label, level_index, chosen
      if chosen.empty?
        label.each_with_index
             .select { |lbl, _| lbl == level_index }.map(&:last)
      else
        chosen.keep_if { |c| label[c] == level_index }
      end
    end

    def remove_layer layer_index
      @levels.delete_at(layer_index)
      @labels.delete_at(layer_index)
      @name.delete_at(layer_index) unless @name.nil?

      coerce_index
    end

    def coerce_index
      if @levels.size == 1
        elements = to_a.flatten

        if elements.uniq.length == elements.length
          Daru::Index.new(elements)
        else
          Daru::CategoricalIndex.new(elements)
        end
      else
        self
      end
    end

    # Array `name` must have same length as levels and labels.
    def validate_name names, levels
      error_msg = "'names' and 'levels' should be of same size. Size of the "\
      "'name' array is #{names.size} and size of the MultiIndex 'levels' and "\
      "'labels' is #{labels.size}."
      suggestion_msg = "If you don\'t want to set name for particular level " \
      "(say level 'i') then put empty string on index 'i' of the 'name' Array."

      raise SizeError, error_msg if names.size > levels.size
      raise SizeError, [error_msg, suggestion_msg].join("\n") if names.size < levels.size
    end

    private :find_all_indexes, :multi_index_from_multiple_selections,
      :retrieve_from_range, :retrieve_from_tuples, :validate_name

    def key index
      raise ArgumentError, "Key #{index} is too large" if index >= @labels[0].size

      @labels
        .each_with_index
        .map { |label, i| @levels[i].keys[label[index]] }
    end

    def dup
      MultiIndex.new levels: levels.dup, labels: labels.dup, name: (@name.nil? ? nil : @name.dup)
    end

    def drop_left_level by=1
      MultiIndex.from_arrays to_a.transpose[by..-1]
    end

    def | other
      MultiIndex.from_tuples(to_a | other.to_a)
    end

    def & other
      MultiIndex.from_tuples(to_a & other.to_a)
    end

    def empty?
      @labels.flatten.empty? && @levels.all?(&:empty?)
    end

    def include? tuple
      return false unless tuple.is_a? Enumerable
      @labels[0...tuple.flatten.size]
        .transpose
        .include?(tuple.flatten.each_with_index.map { |e, i| @levels[i][e] })
    end

    def size
      @labels[0].size
    end

    def width
      @levels.size
    end

    def == other
      self.class == other.class  &&
        labels   == other.labels &&
        levels   == other.levels
    end

    def to_a
      (0...size).map { |e| key(e) }
    end

    def values
      Array.new(size) { |i| i }
    end

    def inspect threshold=20
      "#<Daru::MultiIndex(#{size}x#{width})>\n" +
        Formatters::Table.format([], headers: @name, row_headers: sparse_tuples, threshold: threshold)
    end

    def to_html
      path = File.expand_path('../../iruby/templates/multi_index.html.erb', __FILE__)
      ERB.new(File.read(path).strip).result(binding)
    end

    # Provide a MultiIndex for sub vector produced
    #
    # @param input_indexes [Array] the input by user to index the vector
    # @return [Object] the MultiIndex object for sub vector produced
    def conform input_indexes
      return self if input_indexes[0].is_a? Range
      drop_left_level input_indexes.size
    end

    # Return tuples with nils in place of repeating values, like this:
    #
    # [:a , :bar, :one]
    # [nil, nil , :two]
    # [nil, :foo, :one]
    #
    def sparse_tuples
      tuples = to_a
      [tuples.first] + each_cons(2).map { |prev, cur|
        left = cur.zip(prev).drop_while { |c, p| c == p }
        [nil] * (cur.size - left.size) + left.map(&:first)
      }
    end

    def to_df
      Daru::DataFrame.new(@name.zip(to_a.transpose).to_h)
    end
  end
end
