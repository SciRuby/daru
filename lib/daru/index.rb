module Daru
  class Index
    include Enumerable

    # needs to iterate over keys sorted by their values. Happens right now by 
    # virtue of ordered Hashes (ruby).
    def each(&block)
      @relation_hash.each_key(&block)
    end

    attr_reader :relation_hash

    attr_reader :size

    attr_reader :index_class

    def initialize index
      index = 0 if index.nil?

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

    def +(other)
      if other.respond_to? :relation_hash #another index object
        (@relation_hash.keys + other.relation_hash.keys).uniq.to_index
      elsif other.is_a?(Symbol)
        (@relation_hash.keys << other).to_index
      else
        (@relation_hash.keys + other).uniq.to_index
      end
    end

    def re_index new_index
      new_index.to_index
    end

    def include? index
      @relation_hash.keys.include? index
    end

    def to_index
      self
    end
  end
end