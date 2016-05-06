class Array
  # Recode repeated values on an array, adding the number of repetition
  # at the end
  # Example:
  #   a=%w{a b c c d d d e}
  #   a.recode_repeated
  #   => ["a","b","c_1","c_2","d_1","d_2","d_3","e"]
  def recode_repeated
    return self if size == uniq.size

    duplicated = group_by { |n| n}
                 .select { |_, g| g.size > 1}.map(&:first)

    counter = duplicated.collect { |n| [n, 0] }.to_h

    collect do |n|
      if counter.key?(n)
        counter[n] += 1
        '%s_%d' % [n, counter[n]]
      else
        n
      end
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
    Daru::Index.new to_a
  end
end

class Hash
  def daru_vector index=nil, dtype=:array
    Daru::Vector.new values[0], name: keys[0], index: index, dtype: dtype
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
    map.with_index do |e, index|
      e / other.to_a.flatten[index]
    end
  end
end

class String
  def is_number?
    if self =~ /^-?\d+[,.]?\d*(e-?\d+)?$/
      true
    else
      false
    end
  end
end
