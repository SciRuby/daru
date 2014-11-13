begin
  require 'nyaplot'
rescue LoadError => e
  puts "#{e}"
end

module Daru
  module Plotting
    module Vector

      # Plots a Vector with Nyaplot on IRuby using the given options.
      # == Options
      #   type (:scatter, :bar, :histogram), title, x_label, y_label, color(true/false)
      # 
      # == Usage
      #   vector = Daru::Vector.new [10,20,30,40], [:one, :two, :three, :four]
      #   vector.plot type: :bar, title: "My first plot", color: true
      def plot opts={}
        options = {
          type: :scatter,
          title: "#{@name}",
          x_label: '',
          y_label: '',
          color: false
        }.merge(opts)

        x_axis = options[:type] == :scatter ? Array.new(@size) { |i| i } : @index.to_a
        plot   = Nyaplot::Plot.new 
        p      = plot.add( options[:type], x_axis, @vector.to_a )
        plot.x_label( options[:x_label] )  if options[:x_label]
        plot.y_label( options[:y_label] )  if options[:y_label]
        p.color( Nyaplot::Colors.qual )    if options[:color]

        plot.show
      end
    end
  end
end