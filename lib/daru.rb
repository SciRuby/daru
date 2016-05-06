def jruby?
  RUBY_ENGINE == 'jruby'
end

module Daru
  DAYS_OF_WEEK = {
    'SUN' => 0,
    'MON' => 1,
    'TUE' => 2,
    'WED' => 3,
    'THU' => 4,
    'FRI' => 5,
    'SAT' => 6
  }

  MONTH_DAYS = {
    1 => 31,
    2 => 28,
    3 => 31,
    4 => 30,
    5 => 31,
    6 => 30,
    7 => 31,
    8 => 31,
    9 => 30,
    10 => 31,
    11 => 30,
    12 => 31
  }

  @lazy_update = false

  SPLIT_TOKEN = ','
  class << self
    # A variable which will set whether Vector metadata is updated immediately or lazily.
    # Call the #update method every time a values are set or removed in order to update
    # metadata like positions of missing values.
    attr_accessor :lazy_update

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
require 'daru/core/query.rb'
require 'daru/core/merge.rb'

require 'daru/date_time/offsets.rb'
require 'daru/date_time/index.rb'
