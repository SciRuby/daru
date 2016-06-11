module Daru
  module Category
    attr_accessor :coding_scheme, :base_category
    attr_reader :index

    def initialize_category data, opts={}
      @type = :category

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
      @index = preprocess_index(opts[:index])
      
      # Store metadata
      @metadata = opts[:metadata] || {}
    end

    def each
      return enum_for(:each) unless block_given?
      @array.each { |pos| yield @map_int_cat[pos] }
      self
    end

    def to_a
      each.to_a
    end
    
    def [] *indexes
      positions = @index.pos(*indexes)
      return data_from_position(positions) if positions.is_a? Integer

      Daru::Vector.new positions.map { |pos| data_from_position pos },
        index: @index.subset(*indexes),
        name: @name,
        type: :category,
        ordered: @ordered,
        metadata: @metadata
    end

    def at *positions
      original_positions = positions
      positions = preprocess_positions(*positions)
      validate_positions(*positions)

      return data_from_position(positions) if positions.is_a? Integer
  
      Daru::Vector.new positions.map { |pos| data_from_position(pos) },
        index: @index.at(*original_positions),
        name: @name,
        type: :category,
        ordered: @ordered,
        metadata: @metadata
    end

    def size
      @array.size
    end

    def ordered?
      @ordered
    end

    def ordered= bool
      @ordered = bool
    end

    def categories
      @cat_hash.keys
    end

    def categories= new
      # Change to SizeError
      if new.size != categories.size
        raise ShapeError, "New categories size (#{new.size}) does not match"\
          "with old categories size (#{categories.size})"
      end

      @cat_hash = new.each_with_index.map do |new_cat, i|
        @map_int_cat[i] = new_cat

        old_cat = categories[i]
        [new_cat, @cat_hash[old_cat]]
      end.to_h
    end

    def order= new
      if new.to_set != categories.to_set
        raise ArgumentError, 'The contents of new and old order must be the same.'
      end

      @cat_hash = new.map { |cat| [cat, @cat_hash[cat]] }.to_h
    end

    def min
      assert_ordered 'min'

      categories.first
    end

    def max
      assert_ordered 'max'

      categories.last
    end

    def sort!
      assert_ordered 'sort'

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
      
      @array
    end

    def contrast_code full=false
      send("#{coding_scheme}_coding".to_sym, full)
    end

    def == other
      size == other.size &&
        to_a == other.to_a &&
        index == other.index
    end

    private

    def data_from_position position
      @map_int_cat[@array[position]]
    end

    def assert_ordered operation
      if !ordered?
        # Change ArgumentError to something more expressive
        raise ArgumentError, "Can not apply #{operation} when vector is unordered"
      end      
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

    def preprocess_index index
      index = case index
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
  end
end
