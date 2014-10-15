module Daru
  class Vector
    include Enumerable

    def each(&block)
      @vector.each(&block)
    end

    attr_accessor :name

    attr_reader   :size

    attr_reader   :vector
 
    def initialize source=[], name=nil
      if source.is_a?(Hash)
        initialize source.values[0], source.keys[0]
      else
        @name = name || SecureRandom.uuid

        @vector = 
        case source
        when Range, Matrix
          source.to_a.flatten
        else
          source
        end

        @size = @vector.size
      end
    end

    def [](index)
      @vector[index]
    end

    def []=(index, value)
      @vector[index] = value
    end

    def ==(other)
      other.vector == @vector and other.name == @name and other.size == @size
    end

    def <<(element)
      @vector << element

      @size += 1
    end

    def to_json
      self.to_a.to_json
    end

    def to_a
      @vector.to_a
    end

    def to_nmatrix
      @vector.to_nm
    end

    alias_method :to_nm, :to_nmatrix

    def first lim=1
      lim == 1 ? @vector.first : @vector.first(lim)
    end

    def delete index
      @vector[index] = nil
      @vector.compact!
      @size -= 1
    end

    def to_html threshold=15
      html = '<table><tr><th>' + @name.to_s + '</th></tr>>'

      @vector.to_a.each_with_index do |el,i|
        next if threshold < i and i < @arr.length-1
        content = i == threshold ? '...' : el.to_s
        html.concat('<tr><td>' + content  + '</td></tr>')
      end

      html += '</table>'
    end

    def dup
      Daru::Vector.new @vector.dup, @name
    end

    def daru_vector name=nil
      self
    end

    alias_method :dv, :daru_vector

    def compact!
      @vector.compact!
    end
  end
end