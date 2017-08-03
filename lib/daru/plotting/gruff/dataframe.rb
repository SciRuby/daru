module Daru
  module Plotting
    module DataFrame
      module GruffLibrary
        def plot opts={}
          type = opts[:type] || :bar
          size = opts[:size] || 500
          x = extract_x_vector opts[:x]
          y = extract_y_vectors opts[:y]
          type = process_type type, opts[:categorized]
          case type
          when :line, :bar, :scatter
            plot = send("#{type}_plot", size, x, y)
          when :scatter_categorized
            plot = scatter_with_category(size, x, y, opts[:categorized])
          # TODO: hist, box
          # It turns out hist and box are not supported in Gruff yet
          else
            raise ArgumentError, 'This type of plot is not supported.'
          end
          yield plot if block_given?
          plot
        end

        private

        def process_type type, categorized
          type == :scatter && categorized ? :scatter_categorized : type
        end

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

        def scatter_with_category size, x, y, opts
          x = Daru::Vector.new x
          y = y.first
          plot = Gruff::Scatter.new size
          cat_dv = self[opts[:by]]
          cat_dv.categories.each do |cat|
            bools = cat_dv.eq cat
            plot.data cat, x.where(bools).to_a, y.where(bools).to_a
          end
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
