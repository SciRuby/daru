module Daru
  # MultiIndex is a kind of dataframe Index which represents several levels of nested labels.
  #
  # In addition to usual index operations, it also allows slicing by sublevels.
  #
  # @example
  #   # TODO:
  #   #   construction and inspect
  #   #   access to single row
  #   #   access to subgroup
  #
  # In addition to being useful for storing complex data, MultiIndex is also utilized for structuring
  # aggregated data, returned from {DataFrame#group_by}, {DataFrame#pivot_table} and similar methods.
  #
  # @see Index for explanation about indexes basics.
  #
  class MultiIndex
    extend Forwardable
    include Enumerable
    include IndexSharedBehavior

    attr_reader :relations_hash, :labels, :name
    def_delegators :@labels, :size, :each
    alias to_a labels

    def self.try_create(labels, name: nil)
      return nil unless labels.count > 0 && labels.all? { |l| l.is_a?(Array) && l.size > 1 }
      new(labels, name: name)
    end

    def initialize(labels, name: nil)
      validate_labels(labels)

      @labels = labels.uniq
      @relations_hash = nested_relations_hash(labels.uniq)
      @name = name
    end

    def ==(other)
      other.is_a?(self.class) && labels == other.labels
    end

    def width
      labels.first.size
    end

    def inspect(threshold=20)
      "#<Daru::MultiIndex(#{size}x#{width})>\n" +
        Formatters::Table.format([], headers: @name, row_headers: sparse_tuples, threshold: threshold)
    end

    def label(position)
      labels[position]
    end

    alias key label

    def pos(*labels_or_positions)
      res = relations_hash.dig(*labels_or_positions)
      case res
      when Integer
        res
      when Hash
        positions_from_hash(res)
      else
        TypeCheck[Array, of: Integer].match?(labels_or_positions) ||
          TypeCheck[Range, of: Integer].match?(labels_or_positions.first) or
          raise IndexError, "Undefined index label: #{labels_or_positions}"

        preprocess_positions(labels_or_positions).tap(&method(:validate_positions))
      end
    end

    # FIXME!
    def [](*labels_or_positions)
      pos(*labels_or_positions)
    rescue IndexError
      nil
    end

    def levels
      @labels.transpose.map(&:uniq) # FIXME: Hm?
    end

    # @private
    # Return tuples with nils in place of repeating values, like this:
    #
    # [:a , :bar, :one]
    # [nil, nil , :two]
    # [nil, :foo, :one]
    #
    # Useful for formatted output.
    def sparse_tuples
      tuples = to_a
      [tuples.first] + each_cons(2).map { |prev, cur|
        left = cur.zip(prev).drop_while { |c, p| c == p }
        [nil] * (cur.size - left.size) + left.map(&:first)
      }
    end

    private

    def positions_from_hash(hash)
      hash.values.flat_map { |v| v.is_a?(Integer) ? v : positions_from_hash(v) }
    end

    def validate_labels(labels)
      labels.empty? and raise ArgumentError, 'MultiIndex can not be created from empty labels'
      size_groups = labels.group_by(&:size)
      size_groups.size == 1 or
        raise ArgumentError, 'Different MultiIndex label sizes: ' +
                             size_groups.map(&:last).map(&:first).map(&:inspect).join(', ')

      size_groups.first.first < 2 and
        raise ArgumentError, 'MultiIndex should contain at least 2 values in each label'
    end

    def nested_relations_hash(arrays, start_idx=0)
      arrays.first.size == 1 and
        return arrays.flatten.each_with_index.map { |label, idx| [label, idx + start_idx] }.to_h

      arrays
        .each_with_index
        .group_by { |label, _i| label.first }
        .map { |label, group|
          [
            label,
            nested_relations_hash(group.map(&:first).map { |a| a[1..-1] }, group.first.last)
          ]
        }
        .to_h
    end
  end
end
