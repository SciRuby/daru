module Daru
  module Plotting
    module Vector

      # Plots a Vector with Nyaplot on IRuby using the given options. Yields the
      # plot object (Nyaplot::Plot) and the diagram object (Nyaplot::Diagram) 
      # to the block, which can be used for setting various options as per the 
      # Nyaplot API.
      # 
      # == Options
      #   type (:scatter, :bar, :histogram), title, x_label, y_label, color(true/false)
      # 
      # == Usage
      #   vector = Daru::Vector.new [10,20,30,40], [:one, :two, :three, :four]
      #   vector.plot(type: :bar) do |plot|
      #     plot.title "My first plot"
      #     plot.width 1200
      #   end
      def plot opts={}, &block
        options = {
          type: :scatter
        }.merge(opts)

        x_axis  = options[:type] == :scatter ? Array.new(@size) { |i| i } : @index.to_a
        plot    = Nyaplot::Plot.new
        diagram =
        if [:box, :histogram].include? options[:type]
          plot.add(options[:type], @data.to_a)
        else
          plot.add(options[:type], x_axis, @data.to_a)
        end

        yield plot, diagram if block_given?
        
        plot.show
      end
    end
  end
end if Daru.has_nyaplot?