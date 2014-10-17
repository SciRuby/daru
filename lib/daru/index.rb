module Daru
  class Index

    attr_reader :relation_hash

    attr_reader :size

    def initialize index
      @relation_hash = {}

      index = Array.new(index) { |i| i} if index.is_a? Fixnum

      index.each.with_index do |n, idx|
        n = n.to_sym unless n.is_a?(Numeric)

        @relation_hash[n] = idx 
      end

      @size = @relation_hash.size
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