require 'rake/clean'
require 'rspec/core/rake_task'
require 'rspec'

CLEAN.include( 'coverage' )

desc '"spec" (run RSpec)'
task :default => :spec

desc "Run RSpec on spec/*"
RSpec::Core::RakeTask.new

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,/gems/,/rubygems/']
end

desc "Clean out any generated files"
