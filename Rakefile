require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'open3'

lib_folder = File.expand_path("../lib", __FILE__)

RUBIES = ['ruby-2.0.0-p643', 'ruby-2.1.5', 'ruby-2.2.1', 'ruby-2.3.0']

task :all do |task|
  RUBIES.each do |ruby_v|
    puts "\n  Using #{ruby_v}\n\n"
    command = "$rvm_path/wrappers/#{ruby_v}/rake spec"
    stdout, stderr, status = Open3.capture3(command)
    puts stdout[/^(Finished.*\n.*)$/]
  end
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do |task|
  cmd = [ 'irb', "-r '#{lib_folder}/daru.rb'" ]
  run *cmd
end

task :cop do |task|
  run 'rubocop'
end

task :pry do |task|
  cmd = [ 'pry', "-r '#{lib_folder}/daru.rb'" ]
  run *cmd
end

def run *cmd
  sh(cmd.join(" "))
end