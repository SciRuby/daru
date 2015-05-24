module Daru
  class Index
    include Enumerable

    def each(&block)
      @relation_hash.each_key(&block)
      self
    end

    def map(&block)
      to_a.map(&block)
    end

    attr_reader :relation_hash

    attr_reader :size

    attr_reader :index_class

    def initialize index, values=nil
      @relation_hash = {}

      index = 0                         if index.nil?
      index = Array.new(index) { |i| i} if index.is_a? Integer
      index = index.to_a                if index.is_a? Daru::Index

      if values.nil?
        index.each_with_index do |n, idx|
          n = n.to_sym unless n.is_a?(Integer)

          @relation_hash[n] = idx 
        end
      else
        raise IndexError, "Size of values : #{values.size} and index : #{index.size} do not match" if
          index.size != values.size

        values.each_with_index do |value,i|
          @relation_hash[index[i]] = value
        end
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

      @relation_hash.keys == other.to_a and @relation_hash.values == other.relation_hash.values
    end

    def [](key)
      case key
      when Range
        if key.first.is_a?(Integer) and key.last.is_a?(Integer)
          first = key.first
          last = key.last
        else
          first = @relation_hash[key.first]
          last  = @relation_hash[key.last]
        end

        indexes = []
        (first..last).each do |idx|
          indexes << @relation_hash.key(idx)
        end

        Daru::Index.new indexes, (first..last).to_a
      when Array # works only with numeric indices
        Daru::Index.new key.map { |k| @relation_hash.key(k) }, key
      else
        @relation_hash[key]
      end
    end

    def +(other)
      if other.respond_to? :relation_hash #another index object
        (@relation_hash.keys + other.relation_hash.keys).uniq.to_index
      elsif other.is_a?(Symbol) or other.is_a?(Integer)
        (@relation_hash.keys << other).uniq.to_index
      else
        (@relation_hash.keys + other).uniq.to_index
      end
    end

    def to_a
      @relation_hash.keys
    end

    def key(value)
      @relation_hash.keys[value]
    end

    def include? index
      @relation_hash.has_key? index
    end

    def empty?
      @relation_hash.empty?
    end

    def dup
      Daru::Index.new @relation_hash.keys
    end

    def _dump depth
      Marshal.dump({relation_hash: @relation_hash})
    end

    def self._load data
      h = Marshal.load data

      Daru::Index.new(h[:relation_hash].keys, h[:relation_hash].values)
    end
  end
end