module Daru
  class DataFrame

    attr_reader :vectors

    attr_reader :fields

    attr_reader :size
    
    def initialize source, fields=[], name=SecureRandom.uuid
      if source.empty?
        @vectors = fields.inject({}){|a,x| a[x]=Statsample::Vector.new; a}
      else
        @vectors = source
      end

      @fields = fields.empty? ? source.keys.sort : fields

      check_length
      set_fields_order if @vectors.keys.sort != @fields.sort
    end

   private
    def check_length
      size = nil

      @vectors.each do |name, vector|
        if size.nil?
          size = vector.size
        elsif size != vector.size
          raise Exception, "Expected all vectors to be of the same size. Vector \ 
            #{vector.name} is of size #{vector.size} and another one of size #{size}"    
        end
      end

      @size = size
    end

    def set_fields_order
      @fields = @vectors.keys & @fields
      @fields += @vecorts.keys.sort - @fields
    end
  end
end