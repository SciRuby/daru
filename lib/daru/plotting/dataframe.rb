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
      def plot opts={}
        # FIXME: NO specs for plot at all.
        # May be broken in tens of different ways.
        plot = Nyaplot::Plot.new

        diagram =
          case opts.fetch(:type, :scatter)
          when :scatter, :bar, :line, :histogram
            if single_diagram? opts
              add_single_diagram plot, opts
            else
              add_multiple_diagrams plot, opts
            end
          when :box
            numeric = only_numerics(clone: false).dup_only_valid

            plot.add_with_df(numeric.to_nyaplotdf, :box, *numeric.vectors.to_a)
          end

        yield(plot, diagram) if block_given?

        plot.show
      end

      private

      def single_diagram? options
        options[:x] and options[:x].is_a?(Symbol)
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
          arr = options.keys
          arr.keep_if { |a| a =~ Regexp.new("\\A#{opt}") }.sort
          arr.map { |a| options[a] }
        end
      end
    end
  end
end if Daru.has_nyaplot?
