module Daru
  # Class fir holding multi index on Vector and DataFrame.
  class MultiIndex

    attr_reader :relation_hash
    attr_reader :size
    
    # Initialize a MultiIndex by passing a tuple of indexes. The order assigned
    #   to the multi index corresponds to the position of the tuple in the array
    #   of tuples.
    # 
    # Although you can create your own hierarchially indexed Vectors and DataFrames,
    #   this class currently contains minimal error checking and is mainly used 
    #   internally for summarizing, splitting and grouping of data.
    # 
    # == Arguments
    # 
    # * +source+ - The array of arrays from which the multi index is to be created.
    # 
    # == Usage
    # 
    #   tuples = [:a,:a,:b,:b].zip([:one,:two,:one,:two])
    #   #=> [[:a, :one], [:a, :two], [:b, :one], [:b, :two]]
    #   Daru::MultiIndex.new(tuples)
    def initialize source, opts={}
      @relation_hash = {}
      @size = source.size
      create_relation_hash source
      @relation_hash.freeze
    end

    def [] *indexes
      location = indexes[0]
      if location.is_a?(Symbol)
        result = read_relation_hash @relation_hash, indexes, 0
        result.is_a?(Integer) ? result : Daru::MultiIndex.new(make_tuples(result))
      else
        case location
        when Integer
          self[@relation_hash.keys[location]]
        when Range
          first = location.first
          last  = location.last

          hsh = {}
          first.upto(last) do |index|
            key = @relation_hash.keys[index]
            hsh[key] = read_relation_hash(@relation_hash, [key], 0)
          end
          Daru::MultiIndex.new(make_tuples(hsh))
        end
      end
    end

    # Compare two MultiIndex objects for equality based on the contents of their
    # relation hashes. Does not take object_id into account.
    def == other
      return false if size != other.size
      deep_compare @relation_hash, other.relation_hash
    end

    # Convert a MultiIndex back to tuples (array of arrays). Will retain the 
    # order of creation.
    def to_a
      make_tuples @relation_hash
    end

    # Completely duplicate a MultiIndex object and its contents.
    def dup
      Daru::MultiIndex.new to_a
    end
    
    # Check whether a tuple exists in the multi index. The argument *tuple* can
    # either a complete or incomplete tuple.
    def include? tuple
      !!read_relation_hash(@relation_hash, tuple, 0)
    end

    # Obtain the tuple that correponds with the indentifier number.
    # 
    # == Arguments
    # 
    # * +key+ - A number for which the tuple is to be obtained.
    # 
    # == Usage
    #   
    #   mi.key(3) #=> [:a,:two,:baz]
    def key key
      tuple = find_tuple_for(@relation_hash, key)
      tuple.empty? ? nil : tuple
    end

   private

    # Deep compare two hashes
    def deep_compare this, other
      if this == other
        return true if this.is_a?(Integer) and other.is_a?(Integer)
        this.each_key do |key|
          deep_compare this[key], other[key]
        end
      else
        return false
      end
      true
    end

    # Create tuples out of the relation hash based on the order of the identifier
    # numbers. Returns an array of arrays containing the tuples.
    def make_tuples relation_hash
      tuples = []
      0.upto(@size-1) do |number|
        tuple = find_tuple_for(relation_hash, number)
        tuples << tuple unless tuple.empty?
      end
      tuples
    end

    # Finds and returns a single tuple for a particular identifier number
    def find_tuple_for relation_hash, number
      tuple = []
      search_for_number number, relation_hash, tuple
      tuple.reverse
    end

    # Search for a number and store its corresponding tuple in *tuple*. Returns 
    # true if the number is successfully found.
    def search_for_number number, relation_hash, tuple
      found = false
      relation_hash.each_key do |key|
        value = relation_hash[key]
        if value.is_a?(Hash)
          if search_for_number(number, value, tuple)
            tuple << key
            found = true
          end
        elsif value == number
          tuple << key
          found = true
        end
      end

      found
    end

    # Read the relation hash and return a sub-relation hash or the number to which
    #   indexes belogs to.
    def read_relation_hash relation_hash, indexes, index
      identifier = indexes[index]
      value      = relation_hash[identifier]

      indexes[index+1].nil? ? value : read_relation_hash(value,indexes,index+1)
    end

    # Create the relation hash from supplied tuples.
    def create_relation_hash source
      source.each_with_index do |tuple, number|
        populate @relation_hash, tuple, 0, number
      end   
    end

    def populate relation_hash, tuple, index, number
      identifier = tuple[index]

      if identifier
        if tuple[index+1] 
          relation_hash[identifier] ||= {}
        else
          relation_hash[identifier] = number
          return
        end
        populate relation_hash[identifier], tuple, index+1, number
      end
    end
  end
end