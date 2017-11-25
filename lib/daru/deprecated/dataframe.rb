module Daru
  module Deprecated
    module DataFrame
      def plotting_library=(lib)
        case lib
        when :gruff, :nyaplot
          @plotting_library = lib
          if Daru.send("has_#{lib}?".to_sym)
            extend Module.const_get(
              "Daru::Plotting::DataFrame::#{lib.to_s.capitalize}Library"
            )
          end
        else
          raise ArguementError, "Plotting library #{lib} not supported. "\
            'Supported libraries are :nyaplot and :gruff'
        end
      end
    end
  end
end
