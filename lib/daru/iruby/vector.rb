module Daru
  module IRuby
    module Vector
      # Convert to html for iruby
      def to_html(threshold=30)
        table_thead = to_html_thead
        table_tbody = to_html_tbody(threshold)
        path = if index.is_a?(MultiIndex)
                 File.expand_path('../iruby/templates/vector_mi.html.erb', __FILE__)
               else
                 File.expand_path('../iruby/templates/vector.html.erb', __FILE__)
               end
        ERB.new(File.read(path).strip).result(binding)
      end

      def to_html_thead
        table_thead_path =
          if index.is_a?(MultiIndex)
            File.expand_path('../iruby/templates/vector_mi_thead.html.erb', __FILE__)
          else
            File.expand_path('../iruby/templates/vector_thead.html.erb', __FILE__)
          end
        ERB.new(File.read(table_thead_path).strip).result(binding)
      end

      def to_html_tbody(threshold=30)
        table_tbody_path =
          if index.is_a?(MultiIndex)
            File.expand_path('../iruby/templates/vector_mi_tbody.html.erb', __FILE__)
          else
            File.expand_path('../iruby/templates/vector_tbody.html.erb', __FILE__)
          end
        ERB.new(File.read(table_tbody_path).strip).result(binding)
      end
    end
  end
end
