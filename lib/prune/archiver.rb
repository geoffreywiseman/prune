 #!/usr/bin/ruby
require 'rubygems'
require 'date'
require 'zlib'
require 'archive/tar/minitar'
require 'tmpdir'
require 'minitar'

module Prune

  # Responsible for making or updating archives based on a list of files.
  #
  # This is essentially a wrapper around tar/zlib.
  class Archiver

    # The destination folder to which archives will be written.
    attr_reader :destination

    # Initialize an archiver.
    #
    # @param [string] source the source folder from which files should be archived.
    # @param [boolean] verbose indicates if the output should be verbose
    # @param [string, nil] destination The destination folder to which archives should be written.
    def initialize( destination, source, verbose )
      @source = source
      @verbose = verbose
      @destination = destination || get_default_dir
    end

    # Get the default directory for the archiver, based on the source folder, but with '-archives' appended.
    #
    # @return the default directory
    def get_default_dir
      absolute = File.expand_path @source
      path = File.dirname absolute
      name = File.basename absolute
      File.join( path, "#{name}-archives" )
    end

    # Make the destination directory by creating it if it doesn't already exist.
    #
    # @raise IOError if the folder doesn't exist and can't be created
    def make_destination_dir
      begin
        Dir.mkdir @destination unless File.exists? @destination
      rescue SystemCallError
        raise IOError, "Archive folder #{@destination} does not exist and cannot be created."
      end
    end
    
    # Get a list of all filenames that are not directories within a root folder.
    #
    # @param [String] root the folder in which to look for files
    # @return an array of folders
    def get_filenames( root )
      Dir.entries( root ).map { |tmpfile| File.join( root, tmpfile ) }.reject { |path| File.directory? path }
    end
    
    # Update an archive file by adding additional files to it. This is done by extracting the contents to a
    # temporary folder, then reassembling the archive with the existing and new contents.
    #
    # @param [String] archive_path the path to the archive file
    # @param [Array] paths a list of paths to include in the archive
    def update_archive( archive_path, paths )
      puts "Archive file #{archive_path} exists." if @verbose
      Dir.mktmpdir do |tmp_dir|
        puts "Created temporary directory #{tmp_dir} to extract contents of existing archive file." if @verbose
        tgz = Zlib::GzipReader.new( File.open( archive_path, 'rb' ) )
        Minitar.unpack( tgz, tmp_dir )
        extracted_paths = get_filenames( tmp_dir )
        tgz = Zlib::GzipWriter.new( File.open( archive_path, 'wb' ) )
        Minitar.pack( extracted_paths + paths, tgz )
        puts "Added #{paths.size} file(s) to #{archive_path} archive already containing #{extracted_paths.size} file(s)." if @verbose
      end
    end
    
    # Create a new archive file, and add some files to it.
    #
    # @param [String] archive_path the full filename of the archive file to be created
    # @param [Array] paths the paths of the files to add to the archive
    def create_archive( archive_path, paths )
      tgz = Zlib::GzipWriter.new( File.open( archive_path, 'wb' ) )
      Minitar.pack( paths, tgz )
      puts "Compressed #{paths.size} file(s) into #{archive_path} archive." if @verbose
    end

    # Archive a group of files by creating an archive or updating an existing one.
    # 
    # @param [String] group_name the name of the group , which will be used in deciding the name of the archive
    # @param [Array] files the files to be added to the archive
    def archive( group_name, files )
      make_destination_dir
      archive_path = File.join( @destination, "archive-#{group_name}.tar.gz")
      paths = files.map { |file| File.join( @source, file ) }

      if File.exists?( archive_path ) then
        update_archive( archive_path, paths )
      else
        create_archive( archive_path, paths )
      end

      File.delete( *paths )
      puts "Removing #{files.size} source files that have been archived." if @verbose
    end
  end
end
