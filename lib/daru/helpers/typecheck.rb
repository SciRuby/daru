module Daru
  class TypeCheck
    NONE = Object.new.freeze
    class << self
      def [](klass, of: NONE, size: nil)
        typechecks[[klass, of, size]]
      end

      private

      def typechecks
        @typechecks ||= Hash.new { |h, (klass, of, size)| h[[klass, of, size]] = new(klass, of: of, size: size) }
      end
    end

    def initialize(klass, of: NONE, size: nil)
      @class = klass
      @of = of
      @size = size
    end

    def ===(object) # rubocop:disable Naming/BinaryOperatorParameterName
      object.is_a?(@class) && of(object) && size(object)
    end

    alias match? ===

    private

    # rubocop:disable Style/CaseEquality
    def of(object)
      return true if @of == NONE
      case object
      when Range
        @of === object.begin && @of === object.end
      when Enumerable
        object.count > 0 && object.all? { |o| @of === o }
      else
        raise "Can't use of: option for TypeCheck with #{object}"
      end
    end
    # rubocop:enable Style/CaseEquality

    def size(object)
      return true unless @size
      object.respond_to?(:size) && object.size == @size
    end
  end
end
