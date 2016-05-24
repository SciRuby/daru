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
        options = {
          type:  :scatter
        }.merge(opts)

        plot = Nyaplot::Plot.new
        types = extract_option :type, options

        diagram =
          case
          when !([:scatter, :bar, :line, :histogram] & types).empty?
            if single_diagram? options
              add_single_diagram plot, options
            else
              add_multiple_diagrams plot, options
            end
          when types.include?(:box)
            numeric = only_numerics(clone: false).dup_only_valid

            plot.add_with_df(
              numeric.to_nyaplotdf,
              :box, *numeric.vectors.to_a
            )
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

        diagrams   = []
        nyaplot_df = to_nyaplotdf
        total      = x_vecs.size
        types = types.size < total ? types*total : types

        (0...total).each do |i|
          diagrams << plot.add_with_df(
            nyaplot_df,
            types[i],
            x_vecs[i],
            y_vecs[i]
          )
        end

        diagrams
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
