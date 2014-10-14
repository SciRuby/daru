class Array
  def daru_vector name=nil
    Daru::Vector.new self, name
  end

  alias_method :dv, :daru_vector
end

class Range
  def daru_vector name=nil
    Daru::Vector.new self, name
  end

  alias_method :dv, :daru_vector
end

class Hash
  def daru_vector
    Daru::Vector.new self.values[0], self.keys[0]
  end

  alias_method :dv, :daru_vector
end

class NMatrix
  def daru_vector name=nil
    Daru::Vector.new self
  end

  alias_method :dv, :daru_vector
end

class MDArray
  def daru_vector name=nil
    Daru::Vector.new self, name
  end

  alias_method :dv, :daru_vector
end