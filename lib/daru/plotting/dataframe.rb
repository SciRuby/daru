begin
  require 'nyaplot'
rescue LoadError => e
  puts "#{e}"
end

module Daru
  module Plotting
    module DataFrame
      # Plots a DataFrame with Nyaplot on IRuby using the given options. Yields 
      # the corresponding Nyaplot::Plot object and the Nyaplot::Diagram object
      # to the block, if it is specified. See the nyaplot docs for info on how to
      # further use these objects.
      # 
      # == Options
      # 
      # * +:type+  - Type of plot (scatter, bar, histogram)
      #
      # * +:legends+ - The names of the vectors that are to be used as X and Y axes.
      # The vectors names must be specified as symbols inside an Array. They 
      # also should be specified in the right order. For example, passing [:a, :b]
      # will keep vector :a as the X axis and :b as the Y axis. Passing [:a]
      # keep :a as the X axis and plot the frequency with which :a appears 
      # on the Y axis.
      #
      # * +:frame+ - Pass this as *true* to disable plotting the graph directly
      # and instead manually create Nyaplot::Frame object inside the block using
      # the Nyaplot::Plot object for plotting one or many graphs in a frame.
      # 
      # == Usage
      #   df = Daru::DataFrame.new({a:[0,1,2,3,4], b:[10,20,30,40,50]})
      #   df.plot legends: [:a, :b], type: :bar
      def plot opts={}
        options = {
          type:  :scatter,
          frame: false,
          legends: []
        }.merge(opts)

        plot = Nyaplot::Plot.new
        diagram = plot.add_with_df(Nyaplot::DataFrame.new(self.to_a[0]), 
          options[:type], *options[:legends])

        yield(plot, diagram) if block_given?

        plot.show unless options[:frame]
      end
    end
  end
end