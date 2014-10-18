module Daru
  class DataFrame

    attr_reader :vectors
    attr_reader :index
    attr_reader :name
    attr_reader :size

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    def initialize source, *args
      vectors = args.shift
      index   = args.shift
      @name   = args.shift || SecureRandom.uuid

      raise ArgumentError, "Expected non-nil source" if source.nil?
      @data = []

      if source.empty?
        @vectors = Daru::Index.new vectors
        @index   = Daru::Index.new index

        create_empty_vectors
      else
        case source
        when Array
          @vectors = Daru::Index.new (vectors + (source[0].keys - vectors)).uniq.map(&:to_sym)
          @index   = Daru::Index.new source.size

          create_empty_vectors
        when Hash
          @vectors = Daru::Index.new (vectors + (source.keys - vectors)).uniq.map(&:to_sym)
          @index   = Daru::Index.new index

          @vectors.each do |name|
            @data << source[name].dv(name, @index).dup
          end
        end
      end

      @size = @index.size
      # i want to create a dataframe from a hash (k = name v = array, k = name, v = dv), 
      # array of hashes, empty hash.
      # 
      # For each vector I need to have an index which contains the column names
      # mapped against their order of appearance.
      # For each row I need to have an index.
      # 
      # The vectors will be duplicated before they are stored inside the dataframe
    end

    def [](*names)
      vector names.flatten
    end

    def vector *names
      unless names[1]
        @data[@vectors[names[0]]]
      end
    end

    def has_vector? name
      !!@vectors[name]
    end

    def insert_vector vector, name=nil
      
    end

    def == other
      @index == other.index and @size == other.size and 
      @vectors.each do |vector|
        self[@vectors[vector]] == other[@vectors[vector]]
      end
    end

    def method_missing(name, *args)
      if md = name.match(/(.+)\=/)
        insert_vector name[/(.+)\=/].delete("="), args[0]
      elsif self.has_vector? name
        vector name
      else
        super(name, *args)
      end
    end
   private 

    def create_empty_vectors
      @vectors.each do |name|
        @data << Daru::Vector.new(name, [], @index)
      end
    end

  end
end