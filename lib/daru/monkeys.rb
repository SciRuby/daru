class Array
  def daru_vector name=nil, index=nil, stype=Array
    Daru::Vector.new self, name: name, index: index, stype: stype
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self
  end
end

class Range
  def daru_vector name=nil, index=nil, stype=Array
    Daru::Vector.new self, name: name, index: index, stype: Array
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self.to_a
  end
end

class Hash
  def daru_vector index=nil, stype=Array
    Daru::Vector.new self.values[0], name: self.keys[0], index: index, stype: Array
  end

  alias_method :dv, :daru_vector
end

class NMatrix
  def daru_vector name=nil, index=nil, stype=NMatrix
    Daru::Vector.new self, name: name, index: index, stype: NMatrix
  end

  alias_method :dv, :daru_vector
end

class MDArray
  def daru_vector name=nil, index=nil, stype=MDArray
    Daru::Vector.new self, name: name, index: index, stype: MDArray
  end

  alias_method :dv, :daru_vector
end