#!/usr/bin/ruby
require 'rubygems'
require 'date'

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
      return puts( "ERROR: Retention policy contains no categories." ) if policy.categories.empty?
      policy.categories.each { |cat| @categories[cat] = Array.new } # retain category order
      analyze folder_name, policy
      execute_prune( folder_name, policy ) unless @options[:dry_run]
    end

    def analyze( folder_name, policy )
      print "Analyzing '#{folder_name}':\n"
      files = Dir.entries( folder_name ).sort_by { |f| test(?M, File.join( folder_name, f ) ) }
      files.each do |file|
        analyze_file( policy, file )
      end
      print "\n" if @options[:verbose]

      display_categories( @categories )
      print "\t#{@analyzed_count} file(s) analyzed\n"
    end

    def execute_prune( folder_name, policy )
      begin
        if should_prompt?( policy ) && !prompt then
          puts "Not proceeding; no actions taken."
        else
          take_all_actions( folder_name, policy )
        end
      rescue IOError
        $stderr.print "ERROR: #{$!}\n"
      end
    end

    def should_prompt?( policy )
      @options[:prompt] && actions_require_prompt( policy )
    end

    def actions_require_prompt( policy )
      @categories.keys.any? { |category| category.requires_prompt? }
    end

    def prompt
      print "Proceed? [y/N]: "
      response = STDIN.gets.chomp.strip.downcase
      ['y','yes','true'].include? response
    end

    def take_all_actions( folder_name, policy )
      actions = 0
      @categories.each_pair do |category,files|
        action = category.action
        result = take_action( action, folder_name, files )
        if !result.nil? then
          puts result
          actions += files.size
        end
      end
      print "No actions necessary.\n" if actions == 0
    end

    def take_action( action, folder_name, files )
      case action
      when :remove
        take_remove_action folder_name, files
      when :archive
        take_archive_action folder_name, files
      end
    end
    
    def take_remove_action( folder_name, files )
      if files.empty? then
        "No files categorized to be removed."
      else
        paths = files.map { |file| File.join folder_name, file }
        begin
          File.delete *paths
          "#{files.size} file(s) deleted"
        rescue
          raise IOError, "Could not remove file(s): #{$!}"
        end
      end
    end
    
    def take_archive_action( folder_name, files )
      if @options[:archive] then
        if files.empty? then
          "No files categorized for archival, so no archives created."
        else
          archiver = Archiver.new( @options[:archive_path], folder_name, @options[:verbose] )
          grouper = Grouper.new( archiver )
          grouper.group( folder_name, files );
          grouper.archive
        end
      else
        "Archive option disabled. Archive(s) not created."
      end
    end

    def display_categories( categories )
      categories.each_pair do |category,files|
        if should_display?( category, files ) then 
          print "\t#{category.description}:\n\t\t"
          if files.empty? then
            puts "none"
          else
            puts files.join( "\n\t\t" )
          end
        end
      end
    end
    
    def should_display?( category, files )
      @options[:verbose] || !( category.quiet? || files.empty? )
    end

    def analyze_file( policy, file )
      category = policy.categorize( file )
      @categories[ category ] << file unless category.nil?
      @analyzed_count += 1
    end
    
  end

end