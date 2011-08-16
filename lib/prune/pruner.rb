#!/usr/bin/ruby
require 'rubygems'
require 'optparse'
require 'date'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

module Prune

  class Pruner
    attr_reader :categories
    attr_reader :options
    
    def initialize( options )
      @options = options
      @categories = Hash.new { |h,k| h[k] = [] } # initialize new keys with an empty array
      @analyzed_count = 0
    end
    
    def prune( folder_name )
      return print( "ERROR: Cannot find folder: #{folder_name}\n" ) unless File.exists? folder_name
      return puts( "ERROR: #{folder_name} is not a folder" ) unless File.directory? folder_name
      policy = RetentionPolicy.new folder_name
      analyze folder_name, policy
      execute_prune( folder_name, policy ) unless @options[:dry_run]
    end
    
    def analyze( folder_name, policy )
      print "Analyzing '#{folder_name}':\n"
      files = Dir.entries( folder_name ).sort_by { |f| test(?M, f) } 
      files.each do |file|
        analyze_file( policy, file )
      end
      print "\n" if @options[:verbose]
      
      display_categories policy
      print "\t#{@analyzed_count} file(s) analyzed\n"
    end
    
    def execute_prune( folder_name, policy )
      begin
        if @options[:prompt] && !prompt then
          puts "Not proceeding; no actions taken."
        else
          take_all_actions( folder_name, policy )
        end
      rescue IOError
          $stderr.print "ERROR: #{$!}\n"
      end
    end
    
    def prompt
      print "Proceed? [y/N]: "
      response = STDIN.gets.chomp.strip.downcase
      ['y','yes','true'].include? response
    end
    
    def take_all_actions( folder_name, policy )
      actions = 0
      @categories.each_pair do |category,files|
        action = policy.action( category )
        result = take_action( action, folder_name, files )
        if !result.nil? then
          puts result
          actions += 1
        end
      end
      print "No actions necessary.\n" if actions == 0
    end
    
    def take_action( action, folder_name, files )
      case action
      when :remove
        paths = files.map { |file| File.join folder_name, file }
        begin
          File.delete *paths
          "#{files.size} file(s) deleted"
        rescue
          raise IOError, "Could not remove file(s): #{$!}"
        end
      when :archive
        if @options[:archive] then
          archiver = Archiver.new( @options[:archive_path], folder_name, @options[:verbose] )
          grouper = ArchiveGrouper.new( archiver )
          grouper.group( folder_name, files );
          grouper.archive
        end
      end
    end
    
    def display_categories( policy )
      @categories.each_pair do |category,files|
        print "\t#{policy.describe category} (#{policy.action category}):\n\t\t"
        puts files.join( "\n\t\t")
      end
    end
    
    def analyze_file( policy, file )
      category = policy.categorize( file )
      @categories[ category ] << file unless category.nil?
      @analyzed_count += 1
      print "\t#{file} -> #{category}\n" if @options[:verbose]
    end
  end

end
