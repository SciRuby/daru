module Daru
  module Category # rubocop:disable Metrics/ModuleLength
    UNDEFINED = Object.new.freeze

    attr_accessor :base_category
    attr_reader :index, :coding_scheme, :name

    # Initializes a vector to store categorical data.
    # @note Base category is set to the first category encountered in the vector.
    # @param [Array] data the categorical data
    # @param [Hash] opts the options
    # @option opts [Boolean] :ordered true if data is ordered, false otherwise
    # @option opts [Array] :categories categories to associate with the vector.
    #   It add extra categories if specified and provides order of categories also.
    # @option opts [object] :index gives index to vector. By default its from 0 to size-1
    # @return the categorical data created
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c],
    #     type: :category,
    #     ordered: true,
    #     categories: [:a, :b, :c, 1]
    #   # => #<Daru::Vector(5)>
    #   #   0   a
    #   #   1   1
    #   #   2   a
    #   #   3   1
    #   #   4   c
    def initialize_category data, opts={}
      @type = :category
      initialize_core_attributes data

      if opts[:categories]
        validate_categories(opts[:categories])
        add_extra_categories(opts[:categories] - categories)
        order_with opts[:categories]
      end

      # Specify if the categories are ordered or not.
      # By default its unordered
      @ordered = opts[:ordered] || false

      # The coding scheme to code with. Default is dummy coding.
      @coding_scheme = :dummy

      # Base category which won't be present in the coding
      @base_category = @cat_hash.keys.first

      # Stores the name of the vector
      @name = opts[:name]

      # Index of the vector
      @index = coerce_index opts[:index]

      self
    end

    def name= new_name
      @name = new_name
      self
    end

    def plotting_library= lib
      case lib
      when :gruff, :nyaplot
        @plotting_library = lib
        if Daru.send("has_#{lib}?".to_sym)
          extend Module.const_get(
            "Daru::Plotting::Category::#{lib.to_s.capitalize}Library"
          )
        end
      else
        raise ArgumentError, "Plotting library #{lib} not supported. "\
          'Supported libraries are :nyaplot and :gruff'
      end
    end

    # this method is overwritten: see Daru::Category#plotting_library=
    def plot(*args, **options, &b)
      init_plotting_library

      plot(*args, **options, &b)
    end

    alias_method :rename, :name=

    # Returns an enumerator that enumerates on categorical data
    # @return [Enumerator] an enumerator that enumerates over data stored in vector
    def each
      return enum_for(:each) unless block_given?
      @array.each { |pos| yield cat_from_int pos }
      self
    end

    # Returns all categorical data
    # @return [Array] array of all categorical data which vector is storing
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.to_a
    #   # => [:a, 1, :a, 1, :c]
    def to_a
      each.to_a
    end

    # Duplicated a vector
    # @return [Daru::Vector] duplicated vector
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.dup
    #   # => #<Daru::Vector(5)>
    #   #   0   a
    #   #   1   1
    #   #   2   a
    #   #   3   1
    #   #   4   c
    def dup
      Daru::Vector.new to_a.dup,
        name: @name,
        index: @index.dup,
        type: :category,
        categories: categories,
        ordered: ordered?
    end

    # Associates a category to the vector.
    # @param [Array] new_categories new categories to be associated
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.add_category :b
    #   dv.categories
    #   # => [:a, :b, :c, 1]
    def add_category(*new_categories)
      new_categories -= categories
      add_extra_categories new_categories
    end

    # Returns frequency of given category
    # @param [object] category given category whose count has to be founded
    # @return count/frequency of given category
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.count :a
    #   # => 2
    #   dv.count
    #   # => 5
    def count category=UNDEFINED
      return @cat_hash.values.map(&:size).inject(&:+) if category == UNDEFINED # count all
      raise ArgumentError, "Invalid category #{category}" unless
        categories.include?(category)

      @cat_hash[category].size
    end

    # Returns a vector storing count/frequency of each category
    # @return [Daru::Vector] Return a vector whose indexes are categories
    #   and corresponding values are its count
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.frequencies
    #   # => #<Daru::Vector(4)>
    #   #   a   2
    #   #   b   0
    #   #   c   1
    #   #   1   2
    def frequencies type=:count
      counts = @cat_hash.values.map(&:size)
      values =
        case type
        when :count
          counts
        when :fraction
          counts.map { |c| c / size.to_f }
        when :percentage
          counts.map { |c| c / size.to_f * 100 }
        else
          raise ArgumentError, 'Type should be either :count, :fraction or'\
          " :percentage. #{type} not supported."
        end
      Daru::Vector.new values, index: categories, name: name
    end

    # Returns vector for indexes/positions specified
    # @param [Array] indexes for which values has to be retrived
    # @note Since it accepts both indexes and postions. In case of collision,
    #   argument will be treated as index
    # @return vector containing values specified at specified indexes/positions
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c],
    #     type: :category,
    #     index: 'a'..'e'
    #   dv[:a, 1]
    #   # => #<Daru::Vector(2)>
    #   #   a   a
    #   #   b   1
    #   dv[0, 1]
    #   # => #<Daru::Vector(2)>
    #   #   a   a
    #   #   b   1
    def [] *indexes
      positions = @index.pos(*indexes)
      return category_from_position(positions) if positions.is_a? Integer

      Daru::Vector.new positions.map { |pos| category_from_position pos },
        index: @index.subset(*indexes),
        name: @name,
        type: :category,
        ordered: @ordered,
        categories: categories
    end

    # Returns vector for positions specified.
    # @param [Array] positions at which values to be retrived.
    # @return vector containing values specified at specified positions
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.at 0..-2
    #   # => #<Daru::Vector(4)>
    #   #   0   a
    #   #   1   1
    #   #   2   a
    #   #   3   1
    def at *positions
      original_positions = positions
      positions = coerce_positions(*positions)
      validate_positions(*positions)

      return category_from_position(positions) if positions.is_a? Integer

      Daru::Vector.new positions.map { |pos| category_from_position(pos) },
        index: @index.at(*original_positions),
        name: @name,
        type: :category,
        ordered: @ordered,
        categories: categories
    end

    # Modifies values at specified indexes/positions.
    # @note In order to add a new category you need to associate it via #add_category
    # @param [Array] indexes at which to modify value
    # @param [object] val value to assign at specific indexes/positions
    # @return modified vector
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.add_category :b
    #   dv[0] = :b
    #   dv
    #   # => #<Daru::Vector(5)>
    #   #   0   b
    #   #   1   1
    #   #   2   a
    #   #   3   1
    #   #   4   c
    def []= *indexes, val
      positions = @index.pos(*indexes)

      if positions.is_a? Numeric
        modify_category_at positions, val
      else
        positions.each { |pos| modify_category_at pos, val }
      end
      self
    end

    # Modifies values at specified positions.
    # @param [Array] positions positions at which to modify value
    # @param [object] val value to assign at specific positions
    # @return modified vector
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.add_category :b
    #   dv.set_at [0, 1], :b
    #   # => #<Daru::Vector(5)>
    #   #   0   b
    #   #   1   b
    #   #   2   a
    #   #   3   1
    #   #   4   c
    def set_at positions, val
      validate_positions(*positions)
      positions.map { |pos| modify_category_at pos, val }
      self
    end

    # Size of categorical data.
    # @return total number of values in the vector
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.size
    #   # => 5
    def size
      @array.size
    end

    # Tells whether vector is ordered or not.
    # @return [Boolean] true if vector is ordered, false otherwise
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.ordered?
    #   # => false
    def ordered?
      @ordered
    end

    # Make categorical data ordered or unordered.
    # @param [Boolean] bool true if categorical data is to be to ordered, false otherwise
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.ordered = true
    #   dv.ordered?
    #   # => true
    def ordered= bool
      @ordered = bool
    end

    # Returns all the categories with the inherent order
    # @return [Array] categories of the vector with the order
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c],
    #     type: :category,
    #     categories: [:a, :b, :c, 1]
    #   dv.categories
    #   # => [:a, :b, :c, 1]
    def categories
      @cat_hash.keys
    end

    alias_method :order, :categories

    # Sets order of the categories.
    # @note If extra categories are specified, they get added too.
    # @param [Array] cat_with_order categories specifying their order
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.categories = [:a, :b, :c, 1]
    #   dv.categories
    #   # => [:a, :b, :c, 1]
    def categories= cat_with_order
      validate_categories(cat_with_order)
      add_extra_categories(cat_with_order - categories)
      order_with cat_with_order
    end

    # Rename categories.
    # @note The order of categories after renaming is preserved but new categories
    #   are added at the end in the order. Also the base-category is reassigned
    #   to new value if it is renamed
    # @param [Hash] old_to_new a hash mapping categories whose name to be changed
    #   to their new names
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.rename_categories :a => :b
    #   dv
    #   # => #<Daru::Vector(5)>
    #   #   0   b
    #   #   1   1
    #   #   2   b
    #   #   3   1
    #   #   4   c
    def rename_categories old_to_new
      old_categories = categories
      data = to_a.map do |cat|
        old_to_new.include?(cat) ? old_to_new[cat] : cat
      end

      initialize_core_attributes data
      self.categories = (old_categories - old_to_new.keys) | old_to_new.values
      self.base_category = old_to_new[base_category] if
        old_to_new.include? base_category
      self
    end

    # Removes the unused categories
    # @note If base category is removed, then the first occuring category in the
    #   data is taken as base category. Order of the undeleted categories
    #   remains preserved.
    # @return [Daru::Vector] Makes changes in the vector itself i.e. deletes
    #   the unused categories and returns itself
    # @example
    #   dv = Daru::Vector.new [:one, :two, :one], type: :category,
    #     categories: [:three, :two, :one]
    #   dv.remove_unused_categories
    #   dv.categories
    #   # => [:two, :one]
    def remove_unused_categories
      old_categories = categories

      initialize_core_attributes to_a
      self.categories = old_categories & categories
      self.base_category = @cat_hash.keys.first unless
        categories.include? base_category
      self
    end

    # Returns the minimum category acording to the order specified.
    # @note This operation will only work if vector is ordered.
    #   To set the vector ordered do `vector.ordered = true`
    # @return [object] the minimum category acording to the order
    # @example
    #   dv = Daru::Vector.new ['second', 'second', 'third', 'first'],
    #     categories: ['first', 'second', 'third']
    #   dv.min
    #   # => 'first'
    def min
      assert_ordered :min
      categories.first
    end

    # Returns the maximum category acording to the order specified.
    # @note This operation will only work if vector is ordered.
    #   To set the vector ordered do `vector.ordered = true`
    # @return [object] the maximum category acording to the order
    # @example
    #   dv = Daru::Vector.new ['second', 'second', 'third', 'first'],
    #     categories: ['first', 'second', 'third']
    #   dv.max
    #   # => 'third'
    def max
      assert_ordered :max
      categories.last
    end

    # Sorts the vector in the order specified.
    # @note This operation will only work if vector is ordered.
    #   To set the vector ordered, do `vector.ordered = true`
    # @return [Daru::Vector] sorted vector
    # @example
    #   dv = Daru::Vector.new ['second', 'second', 'third', 'first'],
    #     categories: ['first', 'second', 'thrid'],
    #     type: :categories,
    #     ordered: true
    #   dv.sort!
    #   # => #<Daru::Vector(4)>
    #   #       3  first
    #   #       0 second
    #   #       1 second
    #   #       2  third
    def sort! # rubocop:disable Metrics/AbcSize
      # TODO: Simply the code
      assert_ordered :sort

      # Build sorted index
      old_index = @index.to_a
      new_index = @cat_hash.values.map do |positions|
        old_index.values_at(*positions)
      end.flatten
      @index = @index.class.new new_index

      # Build sorted data
      @cat_hash = categories.inject([{}, 0]) do |acc, cat|
        hash, count = acc
        cat_count = @cat_hash[cat].size
        cat_count.times { |i| @array[count+i] = int_from_cat(cat) }
        hash[cat] = (count...(cat_count+count)).to_a
        [hash, count + cat_count]
      end.first

      self
    end

    def sort
      dup.sort!
    end

    # Set coding scheme
    # @param [Symbol] scheme to set
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.coding_scheme = :deviation
    #   dv.coding_scheme
    #   # => :deviation
    def coding_scheme= scheme
      raise ArgumentError, "Unknown or unsupported coding scheme #{scheme}." unless
        CODING_SCHEMES.include? scheme
      @coding_scheme = scheme
    end

    CODING_SCHEMES = %i[dummy deviation helmert simple].freeze

    # Contrast code the vector acording to the coding scheme set.
    # @note To set the coding scheme use #coding_scheme=
    # @param [Hash] opts The options to pass for coding.
    # @option opts [TrueClass, FalseClass] :full (false) True if you want k variables
    #   for k categories, false if you want k-1 variables for k categories.
    # @return [Daru::DataFrame] dataframe containing all coded variables
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.contrast_code full: false
    #   # => #<Daru::DataFrame(5x2)>
    #   #         daru_1 daru_c
    #   #       0      0      0
    #   #       1      1      0
    #   #       2      0      0
    #   #       3      1      0
    #   #       4      0      1
    def contrast_code opts={}
      if opts[:user_defined]
        user_defined_coding(opts[:user_defined])
      else
        # TODO: Make various coding schemes code DRY
        send("#{coding_scheme}_coding".to_sym, opts[:full] || false)
      end
    end

    # Two categorical vectors are equal if their index and corresponding values are same
    # return [true, false] true if two vectors are similar
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   other = Daru::Vector.new [:a, 1, :a, 1, :c],
    #     type: :category,
    #     index: 1..5
    #   dv == other
    #   # => false
    def == other
      size == other.size &&
        to_a == other.to_a &&
        index == other.index
    end

    # Returns integer coding for categorical data in the order starting from 0.
    # For example if order is [:a, :b, :c], then :a, will be coded as 0, :b as 1 and :c as 2
    # @return [Array] integer coding of all values of vector
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c],
    #     type: :category,
    #     categories: [:a, :b, :c, 1]
    #   dv.to_ints
    #   # => [0, 1, 0, 1, 2]
    def to_ints
      @array
    end

    # Reorder the vector with given positions
    # @note Unlike #reindex! which takes index as input, it takes
    #   positions as an input to reorder the vector
    # @param [Array] order the order to reorder the vector with
    # @return reordered vector
    # @example
    #   dv = Daru::Vector.new [3, 2, 1], index: ['c', 'b', 'a'], type: :category
    #   dv.reorder! [2, 1, 0]
    #   # => #<Daru::Vector(3)>
    #   #   a   1
    #   #   b   2
    #   #   c   3
    def reorder! order
      raise ArgumentError, 'Invalid order specified' unless
        order.sort == size.times.to_a
      # TODO: Room for optimization
      old_data = to_a
      new_data = order.map { |i| old_data[i] }
      initialize_core_attributes new_data
      self
    end

    # Sets new index for vector. Preserves index->value correspondence.
    # @note Unlike #reorder! which takes positions as input it takes
    #   index as an input to reorder the vector
    # @param [Daru::Index, Daru::MultiIndex, Array] idx new index to order with
    # @return [Daru::Vector] vector reindexed with new index
    # @example
    #   dv = Daru::Vector.new [3, 2, 1], index: ['c', 'b', 'a'], type: :category
    #   dv.reindex! ['a', 'b', 'c']
    #   # => #<Daru::Vector(3)>
    #   #   a   1
    #   #   b   2
    #   #   c   3
    def reindex! idx
      idx = Daru::Index.new idx unless idx.is_a? Daru::Index
      raise ArgumentError, 'Invalid index specified' unless
        idx.to_a.sort == index.to_a.sort

      old_categories = categories
      data = idx.map { |i| self[i] }
      initialize_core_attributes data
      self.categories = old_categories
      self.index = idx
      self
    end

    {
      eq: :==,
      not_eq: :!=,
      lt: :<,
      lteq: :<=,
      mt: :>,
      mteq: :>=
    }.each do |method, operator|
      define_method(method) do |other|
        mod = Daru::Core::Query
        if other.is_a?(Daru::Vector)
          mod.apply_vector_operator operator, to_ints, other.to_ints
        else
          mod.apply_scalar_operator operator, @array, int_from_cat(other)
        end
      end
    end
    alias :gt :mt
    alias :gteq :mteq

    # For querying the data
    # @param bool_array [object] arel like query syntax
    # @return [Daru::Vector] Vector which makes the conditions true
    # @example
    #   dv = Daru::Vector.new ['I', 'II', 'I', 'III', 'I', 'II'],
    #     type: :category,
    #     ordered: true,
    #     categories: ['I', 'II', 'III']
    #   dv.where(dv.mt('I') & dv.lt('III'))
    #   # => #<Daru::Vector(2)>
    #   #   1  II
    #   #   5  II
    def where bool_array
      Daru::Core::Query.vector_where self, bool_array
    end

    # Gives the summary of data using following parameters
    # - size: size of the data
    # - categories: total number of categories
    # - max_freq: Max no of times a category occurs
    # - max_category: The category which occurs max no of times
    # - min_freq: Min no of times a category occurs
    # - min_category: The category which occurs min no of times
    # @return [Daru::Vector] Vector with index as following parameters
    #   and values as values to these parameters
    # @example
    #   dv = Daru::Vector.new [:a, 1, :a, 1, :c], type: :category
    #   dv.describe
    #   # => #<Daru::Vector(6)>
    #   #         size            5
    #   #   categories            3
    #   #     max_freq            2
    #   # max_category            a
    #   #     min_freq            1
    #   # min_category            c
    def describe
      Daru::Vector.new(
        size: size,
        categories: categories.size,
        max_freq: @cat_hash.values.map(&:size).max,
        max_category: @cat_hash.keys.max_by { |cat| @cat_hash[cat].size },
        min_freq: @cat_hash.values.map(&:size).min,
        min_category: @cat_hash.keys.min_by { |cat| @cat_hash[cat].size }
      )
    end

    # Does nothing since its already of type category.
    # @return [Daru::Vector] categorical vector
    def to_category
      self
    end

    # Converts a category type vector to non category type vector
    # @return [Daru::Vector] non category type vector
    def to_non_category
      Daru::Vector.new to_a, name: name, index: index
    end

    # Sets index of the vector
    # @param [Daru::Index, Daru::MultiIndex, Daru::CategoricalIndex, Array, Range]
    #   idx new index to assign to vector
    # @return [Daru::Index, Daru::CategoricalIndex, Daru::MultiIndex] the index assigned
    # @example
    #   dv = Daru::Vector.new [1, 2, 3], type: :category
    #   dv.index = 'a'..'c'
    #   dv
    #   # => #<Daru::Vector(3)>
    #   #   a   1
    #   #   b   2
    #   #   c   3
    def index= idx
      @index = coerce_index idx
    end

    # Check if any one of mentioned values occur in the vector
    # @param [Array] values to check for
    # @return [true, false] returns true if any one of specified values
    #   occur in the vector
    # @example
    #   dv = Daru::Vector.new [1, 2, 3, 4, nil]
    #   dv.include_values? nil, Float::NAN
    #   # => true
    def include_values?(*values)
      values.any? { |v| @cat_hash.include?(v) && !@cat_hash[v].empty? }
    end

    # Return a vector with specified values removed
    # @param [Array] values to reject from resultant vector
    # @return [Daru::Vector] vector with specified values removed
    # @example
    #   dv = Daru::Vector.new [1, 2, nil, Float::NAN], type: :category
    #   dv.reject_values nil, Float::NAN
    #   # => #<Daru::Vector(2)>
    #   #   0   1
    #   #   1   2
    def reject_values(*values)
      resultant_pos = size.times.to_a - values.flat_map { |v| @cat_hash[v] }
      dv = at(*resultant_pos)
      unless dv.is_a? Daru::Vector
        pos = resultant_pos.first
        dv = at(pos..pos)
      end
      dv.remove_unused_categories
    end

    # Count the number of values specified
    # @param [Array] values to count for
    # @return [Integer] the number of times the values mentioned occurs
    # @example
    #   dv = Daru::Vector.new [1, 2, 1, 2, 3, 4, nil, nil]
    #   dv.count_values nil
    #   # => 2
    def count_values(*values)
      values.map { |v| @cat_hash[v].size if @cat_hash.include? v }
            .compact
            .inject(0, :+)
    end

    # Return indexes of values specified
    # @param [Array] values to find indexes for
    # @return [Array] array of indexes of values specified
    # @example
    #   dv = Daru::Vector.new [1, 2, nil, Float::NAN], index: 11..14
    #   dv.indexes nil, Float::NAN
    #   # => [13, 14]
    def indexes(*values)
      values &= categories
      index.to_a.values_at(*values.flat_map { |v| @cat_hash[v] }.sort)
    end

    # Replaces specified values with a new value
    # @param [Array] old_values array of values to replace
    # @param [object] new_value new value to replace with
    # @note It performs the replace in place.
    # @return [Daru::Vector] Same vector itself with values
    #   replaced with new value
    # @example
    #   dv = Daru::Vector.new [1, 2, :a, :b]
    #   dv.replace_values [:a, :b], nil
    #   dv
    #   # =>
    #   # #<Daru::Vector:19903200 @name = nil @metadata = {} @size = 4 >
    #   #     nil
    #   #   0   1
    #   #   1   2
    #   #   2 nil
    #   #   3 nil
    def replace_values old_values, new_value
      old_values = [old_values] unless old_values.is_a? Array
      rename_hash = old_values.map { |v| [v, new_value] }.to_h
      rename_categories rename_hash
    end

    def positions(*values)
      values &= categories
      values.flat_map { |v| @cat_hash[v] }.sort
    end

    private

    # Will lazily load the plotting library being used
    def init_plotting_library
      self.plotting_library = Daru.plotting_library
    end

    def validate_categories input_categories
      raise ArgumentError, 'Input categories and speculated categories mismatch' unless
        (categories - input_categories).empty?
    end

    def add_extra_categories extra_categories
      extra_categories.each { |cat| @cat_hash[cat] = [] }
    end

    def initialize_core_attributes data
      # Create a hash to map each category to positional indexes
      categories = data.each_with_index.group_by(&:first)
      @cat_hash = categories.map { |cat, group| [cat, group.map(&:last)] }.to_h

      # Map each category to a unique integer for effective storage in @array
      map_cat_int = categories.keys.each_with_index.to_h

      # To link every instance to its category,
      # it stores integer for every instance representing its category
      @array = map_cat_int.values_at(*data)
    end

    def category_from_position position
      cat_from_int @array[position]
    end

    def assert_ordered operation
      # TODO: Change ArgumentError to something more expressive
      return if ordered?

      raise ArgumentError, "Can not apply #{operation} when vector is unordered. "\
        'To make the categorical data ordered, use #ordered = true'\
    end

    def dummy_coding full
      categories = @cat_hash.keys
      categories.delete(base_category) unless full

      df = categories.map do |category|
        dummy_code @cat_hash[category]
      end

      Daru::DataFrame.new df,
        index: @index,
        order: create_names(categories)
    end

    def dummy_code positions
      code = Array.new(size, 0)
      positions.each { |pos| code[pos] = 1 }
      code
    end

    def simple_coding full
      categories = @cat_hash.keys
      categories.delete(base_category) unless full

      df = categories.map do |category|
        simple_code @cat_hash[category]
      end

      Daru::DataFrame.new df,
        index: @index,
        order: create_names(categories)
    end

    def simple_code positions
      n = @cat_hash.keys.size.to_f
      code = Array.new(size, -1/n)
      positions.each { |pos| code[pos] = (n-1)/n }
      code
    end

    def helmert_coding(*)
      categories = @cat_hash.keys[0..-2]

      df = categories.each_index.map do |index|
        helmert_code index
      end

      Daru::DataFrame.new df,
        index: @index,
        order: create_names(categories)
    end

    def helmert_code index
      n = (categories.size - index).to_f

      @array.map do |cat_index|
        if cat_index == index
          (n-1)/n
        elsif cat_index > index
          -1/n
        else
          0
        end
      end
    end

    def deviation_coding(*)
      categories = @cat_hash.keys[0..-2]

      df = categories.each_index.map do |index|
        deviation_code index
      end

      Daru::DataFrame.new df,
        index: @index,
        order: create_names(categories)
    end

    def deviation_code index
      last = categories.size - 1
      @array.map do |cat_index|
        case cat_index
        when index then 1
        when last  then -1
        else 0
        end
      end
    end

    def user_defined_coding df
      Daru::DataFrame.rows (Array.new(size) { |pos| df.row[at(pos)].to_a }),
        index: @index,
        order: df.vectors.to_a
    end

    def create_names categories
      categories.map do |cat|
        name.is_a?(Symbol) ? "#{name}_#{cat}".to_sym : "#{name}_#{cat}"
      end
    end

    def coerce_index index
      index =
        case index
        when Daru::MultiIndex, Daru::CategoricalIndex, Daru::Index
          index
        when nil
          Daru::Index.new size
        when Range
          Daru::Index.new index.to_a
        when Array
          Daru::Index.new index
        else
          raise ArgumentError, "Unregnized index type #{index.class}"
        end
      validate_index index
      index
    end

    def validate_index index
      # Change to SizeError
      return unless size != index.size

      raise ArgumentError, "Size of index (#{index.size}) does not matches"\
        "size of vector (#{size})"
    end

    def modify_category_at pos, category
      unless categories.include? category
        raise ArgumentError, "Invalid category #{category}, "\
          'to add a new category use #add_category'
      end
      old_category = category_from_position pos
      @array[pos] = int_from_cat category
      @cat_hash[old_category].delete pos
      @cat_hash[category] << pos
    end

    def order_with new
      if new.to_set != categories.to_set
        raise ArgumentError, 'The contents of new and old order must be the same.'
      end

      @cat_hash = new.map { |cat| [cat, @cat_hash[cat]] }.to_h

      map_cat_int = @cat_hash.keys.each_with_index.to_a.to_h
      @array = Array.new(size)
      @cat_hash.map do |cat, positions|
        positions.each { |pos| @array[pos] = map_cat_int[cat] }
      end
    end

    def cat_from_int int
      @cat_hash.keys[int]
    end

    def int_from_cat cat
      @cat_hash.keys.index cat
    end
  end
end
