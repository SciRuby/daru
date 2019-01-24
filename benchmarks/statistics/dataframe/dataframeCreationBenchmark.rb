module DataFrameBenchmark
  def benchmark_create_df_listOflists(size)
    bench = Benchmark.bm do |x|
      report = x.report('Create DataFrame of size :' + size.to_s + ' : ') do
        self.generate_df(size)
      end
      @result_create_df.append("%1.20f" % report.real)
    end
  end

  def create_df_listOfLists(size)
    # for size * size dataframe
    # @df= Daru::DataFrame.new(
    #   Array.new(size) { Array.new(size) { size*rand(1..9) }  }
    # )

    # creaating dataframe of size =  size * 2
    @df= Daru::DataFrame.new(
      Array.new(size) { Array.new(2) { 2*rand(1..9) }  }
    )
    @df_size = size
  end

  def create_df_listOfVector(size)
    # pass
  end

  def create_df_listOfHashes(size)
    # pass
  end

  def create_df_hashOfLists(size)
    # pass
  end

  def create_df_hashOfVector(size)
    # pass
  end
end
