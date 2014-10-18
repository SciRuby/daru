module Daru
  class DataFrame

    attr_reader :data
    attr_reader :vectors
    attr_reader :index
    attr_reader :name

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    def initialize source, *args
      vectors = args.shift
      index   = args.shift
      @name   = args.shift || SecureRandom.uuid

      raise ArgumentError, "Expected non-nil source" if source.nil?
      @vectors = Daru::Index.new vectors
      @index   = Daru::Index.new index
      @data    = []

      if source.empty?
        @vectors.each do |name|
          @data << Daru::Vector.new(name, [], @index)
        end
      else
        case source
        when Array
        when Hash
        end
      end

      # i want to create a dataframe from a hash (k = name v = array, k = name, v = dv), 
      # array of hashes, empty hash.
      # 
      # For each vector I need to have an index which contains the column names
      # mapped against their order of appearance.
      # For each row I need to have an index.
      # 
      # The vectors will be duplicated before they are stored inside the dataframe
    end
  end
end