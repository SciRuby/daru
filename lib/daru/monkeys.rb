class Array
  def daru_vector name=nil, index=nil, dtype=Array
    Daru::Vector.new self, name: name, index: index, dtype: dtype
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self
  end
end

class Range
  def daru_vector name=nil, index=nil, dtype=Array
    Daru::Vector.new self, name: name, index: index, dtype: Array
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self.to_a
  end
end

class Hash
  def daru_vector index=nil, dtype=Array
    Daru::Vector.new self.values[0], name: self.keys[0], index: index, dtype: :array
  end

  alias_method :dv, :daru_vector
end

class NMatrix
  def daru_vector name=nil, index=nil, dtype=NMatrix
    Daru::Vector.new self, name: name, index: index, dtype: :nmatrix
  end

  alias_method :dv, :daru_vector
end

class MDArray
  def daru_vector name=nil, index=nil, dtype=MDArray
    Daru::Vector.new self, name: name, index: index, dtype: :mdarray
  end

  alias_method :dv, :daru_vector
end

class Numeric
  def square
    self * self
  end
end

class Matrix
  def elementwise_division other
    self.map.with_index do |e, index|
      e / other.to_a.flatten[index]
    end
  end
end