# :nocov:
def jruby?
  RUBY_ENGINE == 'jruby'
end
# :nocov:

module Daru
  MISSING_VALUES = [nil, Float::NAN].freeze

  @lazy_update = false

  SPLIT_TOKEN = ','.freeze

  @plotting_library = :nyaplot

  class << self
    # A variable which will set whether Vector metadata is updated immediately or lazily.
    # Call the #update method every time a values are set or removed in order to update
    # metadata like positions of missing values.
    attr_accessor :lazy_update
    attr_reader :plotting_library

    def create_has_library(library)
      lib_underscore = library.to_s.tr('-', '_')
      define_singleton_method("has_#{lib_underscore}?") do
        cv = "@@#{lib_underscore}"
        unless class_variable_defined? cv
          begin
            library = 'nmatrix/nmatrix' if library == :nmatrix
            require library.to_s
            class_variable_set(cv, true)
          rescue LoadError
            # :nocov:
            class_variable_set(cv, false)
            # :nocov:
          end
        end
        class_variable_get(cv)
      end
    end

    def plotting_library= lib
      case lib
      when :gruff, :nyaplot
        @plotting_library = lib
      else
        # :nocov:
        raise ArgumentError, "Unsupported library #{lib}"
        # :nocov:
      end
    end
  end

  create_has_library :gsl
  create_has_library :nmatrix
  create_has_library :nyaplot
  create_has_library :gruff
end

[['reportbuilder', '~>1.4'], ['spreadsheet', '~>1.1.1']].each do |(lib,version)|
  begin
    gem lib, version
    require lib
  rescue LoadError
    # :nocov:
    $stderr.puts "\nInstall #{lib} #{version} to use #{lib} functions."
    # :nocov:
  end
end
