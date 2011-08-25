require 'rake/clean'
require 'rake/packagetask'
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
  t.rcov_opts = ['--exclude', 'spec,/gems/,/rubygems/', '--text-report']
end

Rake::PackageTask.new( "prune", "1.0" ) do |p|
  p.need_tar_gz = true
  p.need_zip = true
  p.package_files.include( '{bin,lib,spec}/**/*', 'Rakefile', 'README.mdown', 'UNLICENSE' )
end
