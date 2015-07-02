def jruby?
  RUBY_ENGINE == 'jruby'
end

module Daru
  SPLIT_TOKEN = ','
  class << self
    @@lazy_update = false
    
    # A variable which will set whether Vector metadata is updated immediately or lazily.
    # Call the #update method every time a values are set or removed in order to update
    # metadata like positions of missing values.
    attr_accessor :lazy_update
    
    def create_has_library(library)
      define_singleton_method("has_#{library}?") do
        cv = "@@#{library}"
        unless class_variable_defined? cv
          begin
            require library.to_s
            class_variable_set(cv, true)
          rescue LoadError
            class_variable_set(cv, false)
          end
        end
        class_variable_get(cv)
      end
    end
  end

  create_has_library :gsl
  create_has_library :nmatrix
  create_has_library :nyaplot
end

autoload :Spreadsheet, 'spreadsheet'
autoload :CSV, 'csv'

require 'matrix'
require 'securerandom'
require 'reportbuilder'

require 'daru/version.rb'
require 'daru/index.rb'
require 'daru/vector.rb'
require 'daru/dataframe.rb'
require 'daru/monkeys.rb'

require 'daru/core/group_by.rb'

require 'daru/date_time/index.rb'
