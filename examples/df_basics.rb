#require_relative '_see'
#see_here(__FILE__, __LINE__)

#require 'bundler/setup'
$:.unshift '../daru' # TODO: temp. I am using "master" branch for examples, while developing refactoring in other folder
require 'daru'

populations = Daru::DataFrame.new(
  {
    Ukraine: [51_838, 49_429, 45_962],
    India: [873_785, 1_053_898, 1_182_108],
    Argentina: [32_730, 37_057, 41_223]
  },
  index: [1990, 2000, 2010],
  name: 'Populations × 1000'
)

populations[:Ukraine][1990]
populations[:Ukraine]
populations.row[1990]
populations[:Ukraine, :India].row[1990, 2010]

populations.each(:row) { |v| p v }
