module Daru
  module IO
    module CSV

      Converters =  {
        boolean: lambda { |f, _|
          case f.downcase.strip
          when 'true'
            true
          when 'false'
            false
          else
            f
          end
        }
      }

    end
  end
end
