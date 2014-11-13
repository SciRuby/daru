begin
  require 'nyaplot'
rescue LoadError => e
  puts "#{e}"
end

module Daru
  module Plotting
    module DataFrame
      # Plots a DataFrame with Nyaplot on IRuby using the given options.
      # == Arguments
      #   +x+ - Vector name to be used for x-axis
      #   +y+ - Vector name to be used for y-axis
      # == Options
      #   type    - Type of plot (scatter, bar, histogram)
      #   title   - Title of plot
      #   x_label - X - label
      #   y_label - Y - label
      #   tooltip_contents - Contents of the tooltip. Array of vector names
      #   fill_by - Vector name by which each plotted element is colored 
      #   shape_by- Vector name by which dots in a scatter plot are shaped
      # == Usage
      #   df = Daru::DataFrame.new({a:[0,1,2,3,4], b:[10,20,30,40,50]})
      #   df.plot :a, :b, type: :bar, title: "Awesome plot"
      def plot x, y, opts={}
        options = {
          type:  :scatter,
          title: "#{@name}",
        }.merge(opts)

        plot = Nyaplot::Plot.new
        p    = plot.add_with_df(Nyaplot::DataFrame.new(self.to_a[0]), options[:type], x, y)
        plot.x_label options[:x_label]                if options[:x_label]
        plot.y_label options[:y_label]                if options[:y_label]
        p.tooltip_contents options[:tooltip_contents] if options[:tooltip_contents]

        if options[:fill_by] or options[:shape_by]
          p.color Nyaplot::Colors.qual
          p.fill_by  options[:fill_by]  if options[:fill_by]
          p.shape_by options[:shape_by] if options[:shape_by]
        end

        plot.show
      end
    end
  end
end