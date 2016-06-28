module Daru
  module Plotting
    module Vector
      module NyaplotLibrary
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
        def plot opts={}
          options = {
            type: :scatter
          }.merge(opts)
  
          x_axis  = options[:type] == :scatter ? Array.new(@size) { |i| i } : @index.to_a
          plot    = Nyaplot::Plot.new
          diagram = create_diagram plot, options[:type], x_axis
  
          yield plot, diagram if block_given?
  
          plot.show
        end
  
        private
  
        def create_diagram plot, type, x_axis
          case type
          when :box, :histogram
            plot.add(type, @data.to_a)
          else
            plot.add(type, x_axis, @data.to_a)
          end
        end        
      end

      module GruffLibrary
        def plot opts={}
          type = opts[:type] || :bar
          size = opts[:size] || 500
          case type
          when :line
            plot = Gruff::Line.new size
            plot.labels = size.times.to_a.zip(index.to_a).to_h
            plot.data name || :vector, to_a
          when :pie, :bar
            plot = Module.const_get("Gruff::#{type.to_s.capitalize}")
              .new size
            each_with_index do |data, index|
              plot.data index, data
            end
          when :scatter
            plot = Gruff::Scatter.new size
            plot.data name || :vector, index.to_a, to_a
          when :sidebar
            plot = Gruff::SideBar.new size
            plot.labels = { 0 => (name.to_s || 'vector') }
            each_with_index do |data, index|
              plot.data index, data
            end
          else
            raise ArgumentError, "This type of plot is not supported."
          end
          yield plot if block_given?
          plot
        end        
      end
    end

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
            plot.show
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

      module GruffLibrary
        def plot opts={}
          type = opts[:type] || :bar
          size = opts[:size] || 500
          case type
          when :bar, :pie
            plot = Module.const_get("Gruff::#{type.to_s.capitalize}")
              .new size
            method = opts[:method] || :count
            frequencies(method).each_with_index do |data, index|
              plot.data index, data
            end
          when :sidebar
            plot = Gruff::SideBar.new size
            plot.labels = { 0 => (name.to_s || 'vector') }
            frequencies(method).each_with_index do |data, index|
              plot.data index, data
            end
          else
            raise ArgumentError, "This type of plot is not supported."
          end
          yield plot if block_given?
          plot
        end        
      end
    end
  end
end
