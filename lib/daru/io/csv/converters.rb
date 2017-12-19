module Daru
  module IO
    module CSV
      CONVERTERS = {
        boolean: lambda { |f, _|
          case f.downcase.strip
          when 'true'
            true
          when 'false'
            false
          else
            f
          end
        },
        string: lambda { |f, _|
          f
        }
      }.freeze
    end
  end
end
