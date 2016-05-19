require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

lib_folder = File.expand_path("../lib", __FILE__)

RUBIES = ['ruby-2.0', 'ruby-2.1', 'ruby-2.2', 'ruby-2.3.0']

task :all do |task|
  RUBIES.each do |ruby_v|
    puts "\n\n\nUsing #{ruby_v}\n\n\n"
    puts `bash -lc "rvm use #{ruby_v}; rspec spec"`
  end
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do |task|
  cmd = [ 'irb', "-r '#{lib_folder}/daru.rb'" ]
  run *cmd
end

task :pry do |task|
  cmd = [ 'pry', "-r '#{lib_folder}/daru.rb'" ]
  run *cmd
end

def run *cmd
  sh(cmd.join(" "))
end