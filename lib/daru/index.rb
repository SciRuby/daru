module Daru
  class Index
    include Enumerable

    def each(&block)
      @relation_hash.each_key(&block)  
    end

    attr_reader :relation_hash

    attr_reader :size

    attr_reader :index_class

    def initialize index
      @relation_hash = {}

      index = Array.new(index) { |i| i} if index.is_a? Integer

      index.each.with_index do |n, idx|
        n = n.to_sym unless n.is_a?(Integer)

        @relation_hash[n] = idx 
      end
      @relation_hash.freeze

      @size = @relation_hash.size

      if index[0].is_a?(Integer)
        @index_class = Integer
      else
        @index_class = Symbol
      end
    end

    def ==(other)
      return false if other.size != @size

      @relation_hash.all? do |k,v|
        v == other.relation_hash[k]
      end
    end

    def [](key)
      @relation_hash[key]
    end

    def to_index
      self
    end
  end
end