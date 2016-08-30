module Daru
  module Plotting
    module Category
      module GruffLibrary
        def plot opts={}
          type = opts[:type] || :bar
          size = opts[:size] || 500
          case type
          when :bar, :pie, :sidebar
            plot = send("category_#{type}_plot".to_sym, size, opts[:method])
          else
            raise ArgumentError, 'This type of plot is not supported.'
          end
          yield plot if block_given?
          plot
        end

        private

        def category_bar_plot size, method
          plot = Gruff::Bar.new size
          method ||= :count
          dv = frequencies(method)
          plot.labels = size.times.to_a.zip(dv.index.to_a).to_h
          plot.data name || :vector, dv.to_a
          plot
        end

        def category_pie_plot size, method
          plot = Gruff::Pie.new size
          method ||= :count
          frequencies(method).each_with_index do |data, index|
            plot.data index, data
          end
          plot
        end

        def category_sidebar_plot size, method
          plot = Gruff::SideBar.new size
          plot.labels = {0 => (name.to_s || 'vector')}
          method ||= :count
          frequencies(method).each_with_index do |data, index|
            plot.data index, data
          end
          plot
        end
      end
    end
  end
end
