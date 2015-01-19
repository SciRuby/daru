def jruby?
  RUBY_ENGINE == 'jruby'
end

require 'csv'
require 'securerandom'

require 'daru/index.rb'
require 'daru/multi_index.rb'
require 'daru/vector.rb'
require 'daru/dataframe.rb'
require 'daru/monkeys.rb'

