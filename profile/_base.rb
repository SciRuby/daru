$:.unshift File.expand_path("../../lib", __FILE__)

require 'ruby-prof'
require 'fileutils'

require 'daru'

def __profile__(name = nil)
  # infers name to be "sorting" when called from "profile/sorting.rb:10:in `<main>'"
  name ||= caller.first.split(':').first.split('/').last.sub('.rb', '')

  path = File.expand_path("../out/#{name}.html", __FILE__)
  FileUtils.mkdir_p File.dirname(path)

  RubyProf.start

  yield

  res = RubyProf.stop
  RubyProf::GraphHtmlPrinter.new(res)
    .print(File.open(path, 'w'))

end
