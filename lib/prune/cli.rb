#!/usr/bin/ruby
require 'rubygems'
require 'optparse'
require 'date'

module Prune
  VERSION = Gem::Version.new '1.2.0.rc4'

  class CommandLineInterface

    DEFAULT_OPTIONS = { :verbose => false, :did_work => false, :dry_run => false, :prompt => true, :archive => true, :configure => false }

    def self.make_parser( options )
      OptionParser.new do |opts|
        opts.banner = "Usage: prune [options] folder"
        opts.on( "-v", "--verbose", "Prints much more frequently during execution about what it's doing." ) { options[:verbose] = true }
        opts.on( "-d", "--dry-run", "Categorizes files, but does not take any actions on them." ) { options[:dry_run] = true }
        opts.on( "-f", "--force", "--no-prompt", "Will take action without asking permissions; useful for automation." ) { options[:prompt] = false }
        opts.on( "-a", "--archive-folder FOLDER", "The folder in which archives should be stored; defaults to <folder>/../<folder-name>-archives." ) { |path| options[:archive_path] = path }
        opts.on( "--no-archive", "Don't perform archival; typically if the files you're pruning are already compressed." ) { options[:archive] = false }
        opts.on( "--config", "Configure the retention policy for the specified folder." ) { options[:configure] = true }
        opts.on_tail( "--version", "Displays version information." ) do
          options[:did_work] = true
          print "Prune #{VERSION}, by Geoffrey Wiseman.\n"
        end
        opts.on_tail( "-?", "--help", "Shows quick help about using prune." ) do
          options[:did_work] = true
          puts opts
        end
      end
    end

    def self.parse_and_run
      options = DEFAULT_OPTIONS.dup
      parser = make_parser options
      begin
        parser.parse!

        if ARGV.size == 1 then
          if options[:configure] then
            configurer = Configurer.new( ARGV.first, options )
            configurer.configure
          else
            Pruner.new( options ).prune( ARGV.first )
          end
        else
          print parser.help unless options[:did_work]
        end
      rescue OptionParser::ParseError
        $stderr.print "Error: " + $!.message + "\n"
      end

    end
  end

end
