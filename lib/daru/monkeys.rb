class Array
  # Recode repeated values on an array, adding the number of repetition
  # at the end
  # Example:
  #   a=%w{a b c c d d d e}
  #   a.recode_repeated
  #   => ["a","b","c_1","c_2","d_1","d_2","d_3","e"]
  def recode_repeated
    if size != uniq.size
      # Find repeated
      repeated = inject({}) do |acc, v|
        if acc[v].nil?
          acc[v] = 1
        else
          acc[v] += 1
        end
        acc
      end.select { |_k, v| v > 1 }.keys

      ns = repeated.inject({}) do |acc, v|
        acc[v] = 0
        acc
      end

      collect do |f|
        if repeated.include? f
          ns[f] += 1
          sprintf('%s_%d', f, ns[f])
        else
          f
        end
      end
    else
      self
    end
  end
  
  def daru_vector name=nil, index=nil, dtype=:array
    Daru::Vector.new self, name: name, index: index, dtype: dtype
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self
  end
end

class Range
  def daru_vector name=nil, index=nil, dtype=:array
    Daru::Vector.new self, name: name, index: index, dtype: dtype
  end

  alias_method :dv, :daru_vector

  def to_index
    Daru::Index.new self.to_a
  end
end

class Hash
  def daru_vector index=nil, dtype=:array
    Daru::Vector.new self.values[0], name: self.keys[0], index: index, dtype: dtype
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