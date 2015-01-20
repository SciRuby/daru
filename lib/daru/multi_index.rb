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
    end

    def [] *indexes
      if indexes[1]
      else
        location = indexes[0]

        case location
        when Symbol
        when Integer
          
        end
      end
    end

   private

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