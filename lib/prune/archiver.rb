#!/usr/bin/ruby
require 'rubygems'
require 'optparse'
require 'date'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

module Prune
  class Archiver
    attr_reader :destination
    
    def initialize( destination, source, verbose )
      @source = source
      @verbose = verbose
      @destination = destination || get_default_dir      
    end
    
    def get_default_dir
      absolute = File.expand_path @source
      path = File.dirname absolute
      name = File.basename absolute
      File.join( path, "#{name}-archives" )
    end
    
    def make_destination
      begin
        Dir.mkdir @destination unless File.exists? @destination
      rescue SystemCallError
        raise IOError, "Archive folder #{@destination} does not exist and cannot be created."
      end
    end
    
    def archive( month, files )
      make_destination
      month_name = Date::ABBR_MONTHNAMES[month]
      archive_path = File.join( @destination, "archive-#{month_name}.tar.gz")
      tgz = Zlib::GzipWriter.new( File.open( archive_path, 'wb' ) )
      paths = files.map { |file| File.join( @source, file ) }
      
      Minitar.pack( paths, tgz )
      puts "Compressed #{files.size} file(s) into #{archive_path} archive." if @verbose
      
      File.delete( *paths )
      puts "Removing #{files.size} compressed file(s)."
    end
  end
end
