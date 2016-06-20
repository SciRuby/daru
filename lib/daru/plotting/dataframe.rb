module Daru
  module Plotting
    module DataFrame
      # Plots a DataFrame with Nyaplot on IRuby using the given options. Yields
      # the corresponding Nyaplot::Plot object and the Nyaplot::Diagram object
      # to the block, if it is specified. See the nyaplot docs for info on how to
      # further use these objects.
      #
      # Detailed instructions on use of the plotting API can be found in the
      # notebooks whose links you can find in the README.
      #
      # == Options
      #
      # * +:type+  - Type of plot. Can be :scatter, :bar, :histogram, :line or :box.
      # * +:x+ - Vector to be used for X co-ordinates.
      # * +:y+ - Vector to be used for Y co-ordinates.
      #
      # == Usage
      #   # Simple bar chart
      #   df = Daru::DataFrame.new({a:['A', 'B', 'C', 'D', 'E'], b:[10,20,30,40,50]})
      #   df.plot type: :bar, x: :a, y: :b
      def plot opts={}, &block
        opts[:categorized]? plot_with_category(opts, &block) :
          plot_without_category(opts, &block)
      end

      private

      def plot_without_category opts
        options = {type:  :scatter}.merge(opts)

        plot = Nyaplot::Plot.new
        types = extract_option :type, options

        diagram =
          case
          when !([:scatter, :bar, :line, :histogram] & types).empty?
            plot_regular_diagrams plot, opts
          when types.include?(:box)
            plot_box_diagram plot
          else
            raise ArgumentError, "Unidentified plot types: #{types}"
          end

        yield(plot, diagram) if block_given?

        plot.show
      end

      def plot_with_category opts
        plot = Nyaplot::Plot.new
        category_opts = opts[:categorized]
        type = opts[:type]
        case type
        when :line, :scatter
          x, y = opts[:x], opts[:y]
          cat_dv = self[category_opts[:by]]

          diagrams = cat_dv.categories.map do |cat|
            x_vec = self[x].where(cat_dv.eq cat)
            y_vec = self[y].where(cat_dv.eq cat)
            df = Daru::DataFrame.new [x_vec, y_vec], order: [x, y]
            nyaplot_df = df.to_nyaplotdf
    
            plot.add_with_df(nyaplot_df, type, x, y)
          end
        else
          raise ArgumentError, "Unsupported type #{type}"
        end

        method = category_opts[:method]
        colors = get_color
        diagrams.zip cat_dv.categories do |d, cat|
          d.title cat
          case method
          when :color
            d.color colors.next
          when :shape
            # TODO: Add categorization by shape
          when :size
            # TODO: Add categorization by size
          else
            raise ArgumentError, "Unkown supported method #{method}"
          end
        end

        plot.legend true
        yield plot, *diagrams if block_given?
        plot.show
      end

      def get_color
        return to_enum(:get_color) unless block_given?        
        loop do
          Nyaplot::Colors.qual.each { |col| yield col }
        end
      end

      def single_diagram? options
        options[:x] && options[:x].is_a?(Symbol)
      end

      def plot_regular_diagrams plot, opts
        if single_diagram? opts
          add_single_diagram plot, opts
        else
          add_multiple_diagrams plot, opts
        end
      end

      def plot_box_diagram plot
        numeric = only_numerics(clone: false).dup_only_valid
        plot.add_with_df(numeric.to_nyaplotdf, :box, *numeric.vectors.to_a)
      end

      def add_single_diagram plot, options
        args = [
          to_nyaplotdf,
          options[:type],
          options[:x]
        ]

        args << options[:y] if options[:y]

        plot.add_with_df(*args)
      end

      def add_multiple_diagrams plot, options
        types  = extract_option :type, options
        x_vecs = extract_option :x, options
        y_vecs = extract_option :y, options

        nyaplot_df = to_nyaplotdf
        total      = x_vecs.size
        types      = types.size < total ? types*total : types

        types.zip(x_vecs, y_vecs).map do |t, xv, yv|
          plot.add_with_df(nyaplot_df, t, xv, yv)
        end
      end

      def extract_option opt, options
        if options[opt]
          o = options[opt]
          o.is_a?(Array) ? o : [o]
        else
          options.keys
                 .select { |a| a =~ Regexp.new("\\A#{opt}") }
                 .sort
                 .map { |a| options[a] }
        end
      end
    end
  end
end if Daru.has_nyaplot?
