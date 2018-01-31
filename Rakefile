require 'rake/clean'
require 'rake/packagetask'
require 'rspec/core/rake_task'
require 'rspec'
require 'rubygems'
require 'rubygems/package_task'

$: << './lib'

require 'prune'

CLEAN.include( 'pkg' )

desc '"spec" (run RSpec)'
task :default => :spec

desc "Run RSpec on spec/*"
RSpec::Core::RakeTask.new

spec = Gem::Specification.new do |spec|
  spec.name = 'geoffreywiseman-prune'
  spec.version = Prune::VERSION
  spec.date = Prune::RELEASE_DATE
  spec.summary = 'Prunes files from a folder based on a retention policy, often time-based.'
  spec.description = 'Prune is meant to analyze a folder full of files, run them against a retention policy and decide which to keep, which to remove and which to archive. It is extensible and embeddable.'
  spec.author = 'Geoffrey Wiseman'
  spec.email = 'geoffrey.wiseman@codiform.com'
  spec.homepage = 'http://geoffreywiseman.github.com/prune'
  spec.executables << 'prune'
  spec.license = "UNLICENSE"
  
  spec.files = Dir['{lib,spec}/**/*.rb', 'bin/*', 'Rakefile', 'README.mdown', 'UNLICENSE']
  
  spec.add_dependency( 'minitar', '~> 0.6' )
end

Gem::PackageTask.new( spec ) do |pkg|
  pkg.need_tar_gz = true
  pkg.need_zip = true
end

# Rake::PackageTask.new( "prune", "1.1.0" ) do |p|
#   p.need_tar_gz = true
#   p.need_zip = true
#   p.package_files.include( '{bin,lib,spec}/**/*', 'Rakefile', 'README.mdown', 'UNLICENSE' )
# end
