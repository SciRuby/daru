module Daru
  class Index

    attr_reader :relation_hash

    def initialize index
      @relation_hash = {}

      index.each.with_index do |n, idx|
        @relation_hash[n.to_sym] = idx
      end
    end

    def ==(other)
      @relation_hash.all? do |k,v|
        v == other.relation_hash[k]
      end
    end

    def [](key)
      @relation_hash[key]
    end
  end
end