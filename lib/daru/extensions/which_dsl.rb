# Support for a simple query DSL for accessing where(), inspired by gem "squeel"

module Daru
  class DataFrame
    # a simple query DSL for accessing where(), inspired by gem "squeel"
    # e.g.:
    # df.which{ `FamilySize` == `FamilySize`.max }
    # equals
    # df.where( df['FamilySize'].eq( df['FamilySize'].max ) )
    #
    # e.g.:
    # df.which{ (`NameTitle` == 'Dr') & (`Sex` == 'female') }
    # equals
    # df.where( df['NameTitle'].eq('Dr') & df['Sex'].eq('female') )
    def which(&block)
      WhichQuery.new(self, &block).exec
    end
  end

  class WhichQuery
    def initialize(df, &condition)
      @df = df
      @condition = condition
    end

    # executes a block of DSL code
    def exec
      query = instance_eval(&@condition)
      @df.where(query)
    end

    def `(vector_name)
      if !@df.has_vector?(vector_name) && @df.has_vector?(vector_name.to_sym)
        vector_name = vector_name.to_sym
      end
      VectorWrapper.new(@df[vector_name])
    end

    class VectorWrapper < SimpleDelegator
      {
        :== => :eq,
        :!= => :not_eq,
        :<  => :lt,
        :<= => :lteq,
        :>  => :mt,
        :>= => :mteq,
        :=~ => :in
      }.each do |opt, method|
        define_method opt do |*args|
          send(method, *args)
        end
      end
    end
  end
end
