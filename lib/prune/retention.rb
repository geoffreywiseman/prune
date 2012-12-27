#!/usr/bin/ruby
require 'rubygems'
require 'date'
require 'pathname'

module Prune

  # Represents a retention policy, whether loaded from the core retention policy or from a project-specific configured retention
  # policy. It defines all the categories, the actions associated with them and some other elements. It is the primary form of
  # prune Configuration.
  class RetentionPolicy
    DEFAULT_OPTIONS={ :load_dsl => true }

    attr_accessor :categories
    
    def initialize( folder_name, options = {} )
      options = DEFAULT_OPTIONS.merge( options )
      @folder_name = folder_name
      @today = Date.today
      @categories = Array.new
      @default_category = Category.new "Unmatched Files", :retain, true
      load_retention_dsl if options[:load_dsl]
    end
    
    def load_retention_dsl()
      instance_eval *get_retention_dsl( @folder_name )
    end
    
    def categorize( file_name )
      file_context = FileContext.new( @folder_name, file_name, @preprocessor )
      @categories.find { |cat| cat.includes? file_context } || @default_category
    end
    
    def get_retention_dsl( folder_name )
      get_dsl( folder_name, '.prune' ) || get_dsl( File.dirname(__FILE__), 'default_retention.rb', 'core retention policy' )
    end
    
    def get_dsl( dsl_folder, dsl_file, human_name=nil )
      dsl = File.join( dsl_folder, dsl_file )
      human_name = Pathname.new( dsl ).cleanpath.to_s if human_name.nil?
      if File.exists?( dsl ) then
        puts "Loading retention policy from: #{human_name}"
        return File.read( dsl ), dsl_file
      else
        return nil
      end
    end
    
    def category( description, &block )
      builder = CategoryBuilder.new( description )
      builder.instance_eval &block
      @categories << builder.build
    end
    
    def preprocess( &block )
      @preprocessor = Proc.new &block
    end
    
  end

  # A builder for building categories -- this is essentially the DSL used in the retention policy.
  class CategoryBuilder
    
    def initialize( description )
      @description = description
      @quiet = false
    end
    
    def build
      if @predicate.nil? then
        raise "Category #{@description} has no predicate defined."
      elsif @action.nil? then
        raise "Category #{@description} has no action defined."
      end
      Category.new( @description, @action, @quiet, @predicate )
    end
    
    def match( &block )
      @predicate = Proc.new &block
    end
    
    def ignore
      @action = :ignore
    end
    
    def retain
      @action = :retain
    end
    
    def archive
      @action = :archive
    end
    
    def remove
      @action = :remove
    end
    
    def quiet
      @quiet = true
    end
    
  end
  
  # A thin wrapper around files for holding attributes that might be precalculated and then
  # used by a number of categories.
  class FileContext
    attr_accessor :name
    
    def initialize( path, filename, preprocessor )
      @name = File.join( path, filename )
      @attributes = Hash.new
      instance_eval &preprocessor unless preprocessor.nil?
    end
    
    # def responds_to?( symbol )
    #   symbol.to_s.end_with? '=' || @attributes.has_key? symbol
    # end
    # 
    def method_missing( symbol, *arguments )
      if symbol.to_s =~ /(.+)=/ && arguments.size == 1 then
        @attributes[ $1.to_sym ] = arguments.first
      elsif @attributes.has_key?( symbol ) && arguments.empty? then
        @attributes[ symbol ]
      else
        super symbol, arguments
      end
    end
    
  end
  
end