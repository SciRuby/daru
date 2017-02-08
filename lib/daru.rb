autoload :CSV, 'csv'
require 'matrix'
require 'forwardable'
require 'erb'
require 'date'

require 'daru/platform.rb'
require 'daru/version.rb'

require 'daru/index/index.rb'
require 'daru/index/multi_index.rb'
require 'daru/index/categorical_index.rb'

require 'daru/helpers/array.rb'
require 'daru/vector.rb'
require 'daru/dataframe.rb'
require 'daru/monkeys.rb'
require 'daru/formatters/table'
require 'daru/iruby/helpers'
require 'daru/exceptions.rb'

require 'daru/core/group_by.rb'
require 'daru/core/query.rb'
require 'daru/core/merge.rb'

require 'daru/date_time/offsets.rb'
require 'daru/date_time/index.rb'

require 'backports'
