module Daru
  module Category
    attr_accessor :coding_scheme, :base_category
    attr_reader :index

    # For debuggin. To be removed
    attr_reader :array, :cat_hash, :map_int_cat

    # Initializes a vector to store categorical data.
    # @param [Array] data the categorical data
    # @param [Hash] opts the options
    # @option opts [Boolean] :ordered true if data is ordered, false otherwise
    # @option opts [Array] :categories categories to associate with the vector.
    #   It add extra categories if specified and provides order of categories also.
    # @option opts [object] :index gives index to vector. By default its from 0 to size-1
    # @option opts [Hash] :metadata metadata associated with the vector.
    # @return the categorical data created
    def initialize_category data, opts={}
      @type = :category

      initialize_core_attributes data

      if opts[:categories]
        validate_categories(opts[:categories])
        add_extra_categories(opts[:categories] - categories)
        set_order opts[:categories]
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
      @index = coerce_index(opts[:index])

      # Store metadata
      @metadata = opts[:metadata] || {}
      self
    end

    # Returns an enumerator that enumerates on categorical data
    # @return [Enumerator] an enumerator that enumerates over data stored in vector
    def each
      return enum_for(:each) unless block_given?
      @array.each { |pos| yield @map_int_cat[pos] }
      self
    end

    # Returns all categorical data
    # @return [Array] array of all categorical data which vector is storing
    def to_a
      each.to_a
    end

    # Associates new category to vector.
    # @param [Array] *new_categories new categories to be added
    def add_category(*new_categories)
      new_categories = new_categories - categories
      add_extra_categories new_categories
    end

    # Returns frequency of given category
    # @param [object] category given category whose count has to be founded
    # @return count/frequency of given category
    def count category
      raise ArgumentError, "Invalid category #{category}" unless
        categories.include?(category)

      @cat_hash[category].size
    end

    # Returns a vector storing count/frequency of each category
    # @return [Daru::Vector] Return a vector whose indexes are categories
    #   and corresponding values are its count
    def frequencies
      Daru::Vector.new @cat_hash.values.map { |val| val.size },
        index: categories
    end

    # Returns vector for indexes/positions specified
    # @param [Array] *indexes indexes/positions for which values has to be retrived
    # @note Since it accepts both indexes and postions. In case of collision,
    #   arguement will be treated as index
    # @return vector containing values specified at specified indexes/positions
    def [] *indexes
      positions = @index.pos(*indexes)
      return category_from_position(positions) if positions.is_a? Integer

      Daru::Vector.new positions.map { |pos| category_from_position pos },
        index: @index.subset(*indexes),
        name: @name,
        type: :category,
        ordered: @ordered,
        metadata: @metadata
    end

    # Returns vector for positions specified.
    # @param [Array] *positions positions at which values to be retrived.
    # @return vector containing values specified at specified positions
    def at *positions
      original_positions = positions
      positions = preprocess_positions(*positions)
      validate_positions(*positions)

      return category_from_position(positions) if positions.is_a? Integer

      Daru::Vector.new positions.map { |pos| category_from_position(pos) },
        index: @index.at(*original_positions),
        name: @name,
        type: :category,
        ordered: @ordered,
        metadata: @metadata
    end

    # Modifies values at specified indexes/positions.
    # @param [Array] *indexes indexes/positions at which to modify value
    # @param [object] val value to assign at specific indexes/positions
    # @return modified vector
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
    def set_at positions, val
      validate_positions(*positions)
      positions.map { |pos| modify_category_at pos, val }
      self
    end

    # Size of categorical data.
    # @return total number of values in the vector
    def size
      @array.size
    end

    # Tells whether vector is ordered or not.
    # @return [Boolean] true if vector is ordered, false otherwise
    def ordered?
      @ordered
    end

    # Make categorical data ordered or unordered.
    # @param [Boolean] bool true if categorical data is to be to ordered, false otherwise
    def ordered= bool
      @ordered = bool
    end

    # Returns all the categories with the inherent order
    # @return [Array] categories of the vector with the order
    def categories
      @cat_hash.keys
    end
    
    alias_method :order, :categories

    # Sets order of the categories.
    # @note If extra categories are specified, they get added too.
    # @param [Array] cat_with_order categories specifying their order
    def categories= cat_with_order
      validate_categories(cat_with_order)
      add_extra_categories(cat_with_order - categories)
      set_order cat_with_order
    end

    # Rename categories.
    # @param [Hash] old_to_new a hash mapping categories whose name to be changed
    #   to their new names
    def rename_categories old_to_new
      @cat_hash = @cat_hash.keys.each_with_index.map do |old_cat, i|
        if old_to_new.include? old_cat
          new_cat = old_to_new[old_cat]
          @map_int_cat[i] = new_cat
          [new_cat, @cat_hash[old_cat]]
        else
          [old_cat, @cat_hash[old_cat]]
        end
      end.to_h
    end

    # Returns the minimum category acording to the order specified.
    # @note This operation will only work if vector is ordered.
    #   To set the vector ordered do `vector.ordered = true`
    # @return [object] the minimum category acording to the order
    def min
      assert_ordered :min
      categories.first
    end

    # Returns the maximum category acording to the order specified.
    # @note This operation will only work if vector is ordered.
    #   To set the vector ordered do `vector.ordered = true`
    # @return [object] the maximum category acording to the order
    def max
      assert_ordered :max
      categories.last
    end

    # Sorts the vector in the order specified.
    # @note This operation will only work if vector is ordered.
    #   To set the vector ordered, do `vector.ordered = true`
    # @return [Daru::Vector] sorted vector
    def sort!
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
        cat_count.times { |i| @array[count+i] = @map_int_cat.key(cat) }
        hash[cat] = (count...(cat_count+count)).to_a
        [hash, count + cat_count]
      end.first

      self
    end

    # Contrast code the vector acording to the coding scheme set.
    # @note To set the coding scheme use #coding_scheme=
    # @param [true, false] full true if you want k variables for k categories,
    #   false if you want k-1 variables for k categories
    # @return [Daru::DataFrame] dataframe containing all coded variables
    def contrast_code full=false
      send("#{coding_scheme}_coding".to_sym, full)
    end

    # Two categorical vectors are equal if their index and corresponding values are same
    # return [true, false] true if two vectors are similar
    def == other
      size == other.size &&
        to_a == other.to_a &&
        index == other.index
    end

    # Returns integer coding for categorical data in the order starting from 0.
    # For example if order is [:a, :b, :c], then :a, will be coded as 0, :b as 1 and :c as 2
    # @return [Array] integer coding of all values of vector
    def to_ints
      @array
    end

    # Over rides original inspect for pretty printing in irb
    def inspect spacing=20, threshold=15
      row_headers = index.is_a?(MultiIndex) ? index.sparse_tuples : index.to_a

      "#<#{self.class}(#{size})#{metadata && !metadata.empty? ? metadata.inspect : ''}>\n" +
        Formatters::Table.format(
          to_a.lazy.map { |v| [v] },
          headers: @name && [@name],
          row_headers: row_headers,
          threshold: threshold,
          spacing: spacing
        )
    end

    # Convert to html for iruby
    def to_html threshold=30
      path =
        if index.is_a?(MultiIndex)
          File.expand_path('../iruby/templates/vector_mi.html.erb', __FILE__)
        else
          File.expand_path('../iruby/templates/vector.html.erb', __FILE__)
        end
      ERB.new(File.read(path).strip).result(binding)
    end

    def to_s
      to_html
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
          mod.apply_scalar_operator operator, @array, @map_int_cat.key(other)
        end
      end
    end
    alias :gt :mt
    alias :gteq :mteq

    def where bool_arry
      Daru::Core::Query.vector_where to_a, @index.to_a, bool_arry, dtype, type
    end

    # TODO Cut function
    def summary
      values = {
        size: size,
        categories: categories.size,
        max_freq: @cat_hash.values.map(&:size).max,
        max_category: @cat_hash.keys.max_by { |cat| @cat_hash[cat].size },
        min_freq: @cat_hash.values.map(&:size).min,
        min_category: @cat_hash.keys.min_by { |cat| @cat_hash[cat].size }
      }
      
      Daru::Vector.new values
    end

    private

    def validate_categories input_categories
      raise ArgumentError, 'Input categories and speculated categories mismatch' unless
        (categories - input_categories).empty?
    end

    def add_extra_categories extra_categories
      total_categories = categories.size
      extra_categories.each_with_index do |cat, index|
        @cat_hash[cat] = []
        @map_int_cat[total_categories+index] = cat
      end
    end

    def initialize_core_attributes data
      # Create a hash to map each category to positional indexes
      categories = data.each_with_index.group_by(&:first)
      @cat_hash = categories.map { |cat, group| [cat, group.map(&:last)] }.to_h

      # Map each category to a unique integer for effective storage in @array
      map_cat_int = categories.keys.each_with_index.to_h

      # Inverse mapping of map_cat_int
      @map_int_cat = map_cat_int.invert

      # To link every instance to its category,
      # it stores integer for every instance representing its category
      @array = map_cat_int.values_at(*data)
    end

    def category_from_position position
      @map_int_cat[@array[position]]
    end

    def assert_ordered operation
      # Change ArgumentError to something more expressive
      raise ArgumentError, "Can not apply #{operation.to_s} when vector is unordered. "\
        'To make the categorical data ordered, use #ordered = true'\
        unless ordered?
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

    def create_names categories
      categories.map { |cat| "#{name}_#{cat}".to_sym }
    end

    def coerce_index index
      index =
        case index
        when nil
          Daru::Index.new size
        when Range
          Daru::Index.new index.to_a
        when Array
          Daru::Index.new index
        when Daru::Index
          index
        else
          raise ArgumentError, "Unregnized index type #{index.class}"
        end
      validate_index index
      index
    end

    def validate_index index
      # Change to SizeError
      raise ArgumentError, "Size of index (#{index.size}) does not matches"\
        "size of vector (#{size})" if size != index.size
    end

    def modify_category_at pos, category
      raise ArgumentError, "Invalid category #{category}, "\
        'to add a new category use #add_category' unless
        categories.include? category
      old_category = category_from_position pos
      @array[pos] = @map_int_cat.key(category)
      @cat_hash[old_category].delete pos
      @cat_hash[category] << pos
    end

    def set_order new
      if new.to_set != categories.to_set
        raise ArgumentError, 'The contents of new and old order must be the same.'
      end

      @cat_hash = new.map { |cat| [cat, @cat_hash[cat]] }.to_h

      map_cat_int = @cat_hash.keys.each_with_index.to_a.to_h
      @map_int_cat = map_cat_int.invert
      @array = Array.new(size)
      @cat_hash.map do |cat, positions|
        positions.each { |pos| @array[pos] = map_cat_int[cat] }
      end
    end    
  end
end
