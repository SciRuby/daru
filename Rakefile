require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

lib_folder = File.expand_path("../lib", __FILE__)

RUBIES = ['ruby-2.0.0-p643', 'ruby-2.1.5', 'ruby-2.2.1', 'ruby-2.3.0']

def spec_run_all
  RUBIES.each do |ruby_v|
    puts "\n  Using #{ruby_v}\n\n"
    command = "$rvm_path/wrappers/#{ruby_v}/rake summary"
    run command
  end
end

task :spec do
  case ARGV[1]
  when 'setup'
    spec_setup
  when 'run'
    spec_run_all if ARGV[2] == 'all'
  when nil
    run 'rspec spec'
  end
end

# Stubs
task :setup
task :run
task :all

def spec_setup
  RUBIES.each do |ruby_v|
    puts "Installing #{ruby_v}..."
    run "rvm install #{ruby_v}"
    path = "$rvm_path/wrappers/#{ruby_v}"
    run "#{path}/gem install bundler"
    run "#{path}/bundle install"
  end
end

#task all: [:cop, :run_all]

task :summary do
  run 'rspec spec/ -r ./.rspec_formatter.rb -f SimpleFormatter' rescue nil
end

#RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do |task|
  cmd = [ 'irb', "-r '#{lib_folder}/daru.rb'" ]
  run *cmd
end

task :cop do |task|
  run 'rubocop' rescue nil
end

task :pry do |task|
  cmd = [ 'pry', "-r '#{lib_folder}/daru.rb'" ]
  run *cmd
end

def run *cmd
  sh(cmd.join(" "))
end

