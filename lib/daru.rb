def jruby?
  RUBY_ENGINE == 'jruby'
end

module Daru
  def self.create_has_library(library)
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
  
  create_has_library :gsl
  create_has_library :nmatrix
  create_has_library :nyaplot
end

require 'csv'
require 'matrix'
require 'securerandom'

require 'daru/index.rb'
require 'daru/multi_index.rb'
require 'daru/vector.rb'
require 'daru/dataframe.rb'
require 'daru/monkeys.rb'

require 'daru/core/group_by.rb'
