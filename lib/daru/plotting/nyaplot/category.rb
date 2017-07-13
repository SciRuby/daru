module Daru
  module Plotting
    module Category
      module NyaplotLibrary
        def plot opts
          case type = opts[:type]
          when :bar
            plot = Nyaplot::Plot.new
            opts[:method] ||= :count
            values = frequencies opts[:method]
            diagram = plot.add :bar, values.index.to_a, values.to_a
            # Set yrange for good view
            set_yrange plot, opts[:method]
            yield plot, diagram if block_given?
            plot
          else
            raise ArgumentError, "#{type} type is not supported."
          end
        end

        private

        def set_yrange plot, method
          case method
          when :percentage
            plot.yrange [0, 100]
          when :fraction
            plot.yrange [0, 1]
          end
        end
      end
    end
  end
end
