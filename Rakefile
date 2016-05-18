require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

lib_folder = File.expand_path("../lib", __FILE__)

RUBIES = ['ruby-2.0.0', 'ruby-2.1.1', 'ruby-2.2.1', 'jruby']

task :spec do |task|
  RUBIES[0..1].each do |ruby_v|
    puts "\n\n\n Using Ruby #{ruby_v}\n\n\n"
    puts `bash -lc "rvm use #{ruby_v}; rspec spec"`
  end
end

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