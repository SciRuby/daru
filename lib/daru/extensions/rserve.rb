# Support for converting data to R data structures to support rserve-client

module Daru
  class DataFrame
    def to_REXP # rubocop:disable Style/MethodName
      names = @vectors.to_a
      data  = names.map do |f|
        Rserve::REXP::Wrapper.wrap(self[f].to_a)
      end
      l = Rserve::Rlist.new(data, names.map(&:to_s))

      Rserve::REXP.create_data_frame(l)
    end
  end

  class Vector
    def to_REXP # rubocop:disable Style/MethodName
      Rserve::REXP::Wrapper.wrap(to_a)
    end
  end
end
