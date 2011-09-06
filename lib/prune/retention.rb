#!/usr/bin/ruby
require 'rubygems'
require 'date'

module Prune

  class RetentionPolicy

    def initialize( folder_name )
      @folder_name = folder_name
      @today = Date.today
      @categories = Array.new
      @default_category = Category.new "Unmatched Files", :retain
      instance_eval *get_retention_dsl
      raise "No categories defined." if @categories.empty?
    end
    
    def categorize( file_name )
      file_context = FileContext.new( @folder_name, file_name, @preprocessor )
      @categories.find { |cat| cat.includes? file_context } || @default_category
    end
    
    def get_retention_dsl
      return File.read( File.join( File.dirname( __FILE__ ), 'default_retention.rb' ) ), 'default_retention.rb'
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
  
  class CategoryBuilder
    
    def initialize( description )
      @description = description
    end
    
    def build
      if @predicate.nil? then
        raise "Category #{@description} has no predicate defined."
      elsif @action.nil? then
        raise "Category #{@description} has no action defined."
      end
      Category.new( @description, @action, @predicate )
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
    
  end
  
  class Category
    attr_accessor :action, :description
    
    def initialize( description, action, predicate = Proc.new { |x| true } )
      @description = description
      @action = action
      @predicate = predicate
    end
    
    def requires_prompt?
      case @action
      when :remove
        true
      when :archive
        true
      else
        false
      end
    end
    
    def includes?( filename )
      @predicate.call filename
    end
  end
  
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