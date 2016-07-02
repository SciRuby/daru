module Daru
  module Plotting
    module DataFrame
      module NyaplotLibrary
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
          if opts[:categorized]
            plot_with_category(opts, &block)
          else
            plot_without_category(opts, &block)
          end
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
          case type = opts[:type]
          when :scatter, :line
            plot = Nyaplot::Plot.new
            category_opts = opts[:categorized]
            type = opts[:type]
            x, y = opts[:x], opts[:y]
            cat_dv = self[category_opts[:by]]

            diagrams = create_categorized_diagrams plot, cat_dv, x, y, type

            apply_variant_to_diagrams diagrams, category_opts, type

            plot.legend true
            yield plot, *diagrams if block_given?
            plot.show

          else
            raise ArgumentError, "Unsupported type #{type}"
          end
        end

        def create_categorized_diagrams plot, cat_dv, x, y, type
          cat_dv.categories.map do |cat|
            x_vec = self[x].where(cat_dv.eq cat)
            y_vec = self[y].where(cat_dv.eq cat)
            df = Daru::DataFrame.new [x_vec, y_vec], order: [x, y]
            nyaplot_df = df.to_nyaplotdf

            plot.add_with_df(nyaplot_df, type, x, y)
          end
        end

        def apply_variant_to_diagrams diagrams, category_opts, type
          method = category_opts[:method]
          cat_dv = self[category_opts[:by]]
          # If user has mentioned custom color, size, shape use them
          variant =
            if category_opts[method]
              category_opts[method].cycle
            else
              send("get_#{method}".to_sym, type)
            end

          diagrams.zip(cat_dv.categories) do |d, cat|
            d.title cat
            d.send(method, variant.next)
            d.tooltip_contents [cat]*cat_dv.count(cat) if type == :scatter
          end
        end

        SHAPES = %w(circle triangle-up diamond square triangle-down cross).freeze
        def get_shape type
          validate_type type, :scatter
          SHAPES.cycle
        end

        def get_size type
          validate_type type, :scatter
          (50..550).step(100).cycle
        end

        def get_color(*)
          Nyaplot::Colors.qual.cycle
        end

        def get_stroke_width type
          validate_type type, :line
          (2..16).step(2).cycle
        end

        def validate_type type, *types
          raise ArgumentError, "Invalid option for #{type} type" unless
            types.include? type
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

      module GruffLibrary
        def plot opts={}
          type = opts[:type] || :bar
          size = opts[:size] || 500
          x = extract_x_vector opts[:x]
          y = extract_y_vectors opts[:y]
          return plot_with_category(
            size, type, x, y, opts[:categorized]
          ) if opts[:categorized]
          case type
          when :line, :bar, :scatter
            plot = send("#{type}_plot", size, x, y)
          # TODO: hist, box
          # It turns out hist and box are not supported in Gruff yet
          else
            raise ArgumentError, 'This type of plot is not supported.'
          end
          yield plot if block_given?
          plot
        end

        private

        def line_plot size, x, y
          plot = Gruff::Line.new size
          plot.labels = size.times.to_a.zip(x).to_h
          y.each do |vec|
            plot.data vec.name || :vector, vec.to_a
          end
          plot
        end

        def bar_plot size, x, y
          plot = Gruff::Bar.new size
          plot.labels = size.times.to_a.zip(x).to_h
          y.each do |vec|
            plot.data vec.name || :vector, vec.to_a
          end
          plot
        end

        def scatter_plot size, x, y
          plot = Gruff::Scatter.new size
          y.each do |vec|
            plot.data vec.name || :vector, x, vec.to_a
          end
          plot
        end

        def plot_with_category size, type, x, y, opts
          x = Daru::Vector.new x
          y = y.first
          case type
          when :scatter
            plot = Gruff::Scatter.new size
            cat_dv = self[opts[:by]]
            cat_dv.categories.each do |cat|
              bools = cat_dv.eq cat
              plot.data cat, x.where(bools).to_a, y.where(bools).to_a
            end
          else
            raise ArgumentError, "Type #{type} is not supported."
          end
          yield plot if block_given?
          plot
        end

        def extract_x_vector x_name
          x_name && self[x_name].to_a || index.to_a
        end

        def extract_y_vectors y_names
          y_names =
            case y_names
            when nil
              vectors.to_a
            when Array
              y_names
            else
              [y_names]
            end

          y_names.map { |y| self[y] }.select(&:numeric?)
        end
      end
    end
  end
end
