class Array
  def daru_vector name=nil, index=nil
    Daru::Vector.new name, self, index
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self
  end
end

class Range
  def daru_vector name=nil, index=nil
    Daru::Vector.new name, self, index
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self.to_a
  end
end

class Hash
  def daru_vector index=nil
    Daru::Vector.new self.keys[0], self.values[0], index
  end

  alias_method :dv, :daru_vector
end

class NMatrix
  def daru_vector name=nil, index=nil
    Daru::Vector.new name, self, index
  end

  alias_method :dv, :daru_vector
end

class MDArray
  def daru_vector name=nil, index=nil
    Daru::Vector.new name, self, index
  end

  alias_method :dv, :daru_vector
end