#!/usr/bin/ruby
require 'rubygems'
require 'optparse'
require 'date'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

module Prune
  VERSION = [1,0,0]
  
  class CommandLineInterface
    def self.parse_and_run
      options = { :verbose => false, :did_work => false, :dry_run => false, :prompt => true, :archive => true }
      parser = OptionParser.new do |opts|
          opts.banner = "Usage: prune [options] folder"
          opts.on( "-v", "--verbose", "Prints much more frequently during execution about what it's doing." ) { options[:verbose] = true }
          opts.on( "-d", "--dry-run", "Categorizes files, but does not take any actions on them." ) { options[:dry_run] = true }
          opts.on( "-f", "--force", "--no-prompt", "Will take action without asking permissions; useful for automation." ) { options[:prompt] = false }
          opts.on( "-a", "--archive-folder", "The folder in which archives should be stored; defaults to <folder>/../<folder-name>-archives." ) { |path| options[:archive_path] = path }
          opts.on( "--no-archive", "Don't perform archival; typically if the files you're pruning are already compressed." ) { options[:archive] = false }
          opts.on_tail( "--version", "Displays version information." ) do 
            options[:did_work] = true
            puts "Prune #{VERSION.join('.')}, by Geoffrey Wiseman."
          end
          opts.on_tail( "-?", "--help", "Shows quick help about using prune." ) do
            options[:did_work] = true
            puts opts
          end
      end

      begin
        parser.parse!
      rescue OptionParser::ParseError
        $stderr.print "Error: " + $! + "\n"
        exit
      end
      
      if ARGV.size != 1 then
        print parser.help unless options[:did_work]
      else
        Pruner.new( options ).prune( ARGV.first )
      end
    end
  end

end
