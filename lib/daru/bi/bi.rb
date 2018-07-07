module Daru
  module BI
    # cluster records using K-Means algorithm
    # @param cols [Array] array of columns to be used for clustering
    # @param centroids [Integer] number of centroids
    # @return clusters of indices
    # @example
    #   df = Daru::DataFrame.new({
    #      REF: [2002, 2003, 3001, 3002, 3003]
    #      Handle: [t-shirt1, t-shirt1, t-shirt2, t-shirt2, t-shirt2]
    #      Size: [M, L, S, M, L]
    #      Price: [23,23,24,24,24]
    #   })
    #   df.cluster_kmeans [:Size, :Price], 2
    #   # => [[0,1],[2,3,4]]
    #   df.cluster_kmeans [:Size, :Price], 3
    #   # => [[0,3],[1,4],[2]]
    def cluster_kmeans cols, centroids
      # TODO
    end

    # cluster records by hierarchy for details of algorithm visit
    # https://onlinecourses.science.psu.edu/stat555/node/86/
    # @param cols [Array] array of columns to be used for clustering
    # @return hierarchical clusters of indices
    # @example example using a simple array of coordiantes
    #   df = Daru::DataFrame.new({
    #      REF: [2002, 2009, 2012, 3016, 2003]
    #      Handle: [t-shirt1, t-shirt1, t-shirt2, t-shirt2, t-shirt2]
    #      Size: [M, L, S, M, L]
    #      Price: [23,23,24,24,24]
    #   })
    #   df.cluster_hier [:REF]
    #   # =>  [[[2002,2003],[2009,2012]],3016]
    def cluster_hier cols
      # TODO
    end

    # Returns a sample obtained by the systematic technique: A member occurring after a fixed 
    # interval is selected. The member occurring after fixed interval is known as Kth element.
    # @params k [Integer] the length of interval
    # @return dataframe with the obtained sample
    # @example
    #   df = Daru::DataFrame.new({a: (1..98), b: [50]*98})
    #   df.sample_systematic 25
    #   # => #<Daru::DataFrame(3x2)>
    #   #       a   b
    #   #   0  25  50
    #   #   1  50  50
    #   #   2  75  50
    def sample_systematic k = 10
      # TODO
    end

    # Returns a sample obtained in a stratified way: A member occurring after a fixed 
    # interval is selected. The member occurring after fixed interval is known as Kth element.
    # @params col [Integer] the column whose division is to be specified
    # @params division [Hash] represents the strata (sub-groups), keys can be
    # ranges or arrays and sample size drawn from the stratum is corresponding value
    # @return dataframe with the obtained sample
    # @example
    #   df = Daru::DataFrame.new({a: (1..98), b: (3..100)})
    #   df.sample_stratified :b, {[3,4,12,14]=>2, (25..36)=>3}
    #   # => #<Daru::DataFrame(3x2)>
    #   #       a   b
    #   #   0   2   4
    #   #   1  12  14
    #   #   2  27  29
    #   #   3  28  30
    #   #   4  33  35
    def sample_stratified col, division
      # TODO
    end
  end
end
