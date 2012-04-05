#!/usr/bin/ruby
require 'rubygems'
require 'date'
require 'zlib'
require 'archive/tar/minitar'
require 'tmpdir'
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

    def make_destination_dir
      begin
        Dir.mkdir @destination unless File.exists? @destination
      rescue SystemCallError
        raise IOError, "Archive folder #{@destination} does not exist and cannot be created."
      end
    end

    def archive( group_name, files )
      make_destination_dir
      archive_path = File.join( @destination, "archive-#{group_name}.tar.gz")
      paths = files.map { |file| File.join( @source, file ) }

      if File.exists?( archive_path ) then
        puts "Archive file #{archive_path} exists." if @verbose
        Dir.mktmpdir do |tmp_dir|
          puts "Created temporary directory #{tmp_dir} to extract contents of existing archive file." if @verbose
          tgz = Zlib::GzipReader.new( File.open( archive_path, 'rb' ) )
          Minitar.unpack( tgz, tmp_dir )
          extracted_paths = Dir.entries( tmp_dir ).map { |tmpfile| File.join( tmp_dir, tmpfile ) }.reject { |path| File.directory? path }
          combined_paths = extracted_paths + paths
          tgz = Zlib::GzipWriter.new( File.open( archive_path, 'wb' ) )
          Minitar.pack( combined_paths, tgz )
          puts "Added #{files.size} file(s) to #{archive_path} archive already containing #{extracted_paths.size} file(s)." if @verbose
        end
      else
        tgz = Zlib::GzipWriter.new( File.open( archive_path, 'wb' ) )
        Minitar.pack( paths, tgz )
        puts "Compressed #{files.size} file(s) into #{archive_path} archive." if @verbose
      end

      File.delete( *paths )
      puts "Removing #{files.size} source files that have been archived." if @verbose
    end
  end
end
