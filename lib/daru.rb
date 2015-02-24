def jruby?
  RUBY_ENGINE == 'jruby'
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
