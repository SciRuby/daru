module Daru
  module BI
    # cluster records using K-Means algorithm
    # @param cols [Array] array of columns to be used for clustering
    # @param centroids [Integer] number of centroids
    # @return clusters of indices
    # @example
    #   df = Daru::DataFrame.new({
    #      REF: [2002, 2003, 3001, 3002, 3003],
    #      Handle: ['t-shirt1', 't-shirt1', 't-shirt2', 't-shirt2', 't-shirt2'],
    #      Size: ['M', 'L', 'S', 'M', 'L'],
    #      Price: [23,23,24,24,24]
    #   })
    #   df.cluster_kmeans [:Size, :Price], 2
    #   # => [[0,1],[2,3,4]]
    #   df.cluster_kmeans [:Size, :Price], 3
    #   # => [[0,3],[1,4],[2]]
    require 'k_means' 
    def cluster_kmeans cols, centroids
      KMeans.new(self[*cols].to_df.to_a[0..-2][0].map {|h| h.values}, centroids: centroids)
    end

    # cluster records by hierarchy for details of algorithm visit
    # https://onlinecourses.science.psu.edu/stat555/node/86/
    # @param cols [Array] array of columns to be used for clustering, can contain
    # one or two elements
    # @return [Hierclust::Cluster] hierarchical clusters of indices
    # @example example using a simple array of coordiantes
    #   df = Daru::DataFrame.new({
    #      REF: [2002, 2003, 3001, 3002, 3003],
    #      Handle: ['t-shirt1', 't-shirt1', 't-shirt2', 't-shirt2', 't-shirt2'],
    #      Size: ['M', 'L', 'S', 'M', 'L'],
    #      Price: [23,23,24,24,24]
    #   })
    #   cluster = df.cluster_hier [:REF,:Price]
    #   cluster.to_a
    #   # =>  "[[[(3001, 24), (3002, 24)], (3003, 24)], [(2002, 23), (2003, 23)]]"
    require 'hierclust'
    def cluster_hier cols
      points = self[cols[0]].each_with_index
                .map { |x, y| Hierclust::Point.new(x, cols[1] ? self[cols[1]][y] : 0) }
      helper_hier Hierclust::Clusterer.new(points).clusters[0]
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
    #   #   0   1  50
    #   #  25  26  50
    #   #  50  51  50
    #   #  75  76  50
    def sample_systematic k = 10
      self.row_at(*@index.to_a.select { |x| x % k == 0 })
    end

    # Returns a sample obtained in a stratified way: A member occurring after a fixed 
    # interval is selected. The member occurring after fixed interval is known as Kth element.
    # @params division [Hash] represents the strata (sub-groups), keys can be
    # ranges or arrays and sample size drawn from the stratum is corresponding value
    # @return dataframe with the obtained sample
    # @example
    #   df = Daru::DataFrame.new({a: (1..98), b: (3..100)})
    #   df.sample_stratified {[3,4,12,14]=>2, (25..36)=>3}
    #   # => #<Daru::DataFrame(3x2)>
    #   #       a   b
    #   #   0  15  17
    #   #   1   4   6
    #   #   2  29  31
    #   #   3  35  37
    #   #   4  33  35
    def sample_stratified division
      df = self.row[]
      division.each do |group, num|
        if(num == 1)
          df.add_row(self.row_at(*group.to_a.sample(num)))
        else
          df = df.concat(self.row_at(*group.to_a.sample(num)))
        end
      end
      df
    end

    private

    def helper_hier cluster
      cluster.items.map { |item| item.class == Hierclust::Point ? [item.x, item.y] : helper_hier(item) }
    end
  end
end
