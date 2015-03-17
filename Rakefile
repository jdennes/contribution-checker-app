begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # Avoid errors when development and test dependencies aren't present
end

task :test => :spec
task :default => :spec
