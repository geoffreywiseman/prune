#!/usr/bin/ruby
require 'rubygems'
require 'optparse'
require 'date'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

module Prune

  class RetentionPolicy
  
    def initialize( folder_name )
      @folder_name = folder_name
      @today = Date.today
    end
  
    def categorize( file_name )
      path = File.join( @folder_name, file_name )
      created = Date.parse(File.mtime(path).strftime('%Y/%m/%d'))
      if File.directory? path then
        :dir
      elsif @today - created < 14 then
        :recent
      elsif @today.year == created.year && ( @today.month - created.month ) <= 1 then
        # this month, last month
        created.wday == 5 ? :sparse : :remove
      else 
        # earlier month
        created.wday == 5 ? :old : :remove
      end
    end
    
    def describe( category )
      case category
      when :dir
        "Directories"
      when :recent
        "Less than 2 Weeks Old"
      when :sparse
        "Friday Older than 2 Weeks"
      when :remove
        "Older than 2 Weeks, Not Friday"
      when :old
        "Friday Older than 2 Months"
      end
    end
    
    def action( category )
      case category
      when :dir
        :ignore
      when :recent
        :retain
      when :sparse
        :retain
      when :remove
        :remove
      when :old
        :archive
      end
    end
  
  end
  
end
