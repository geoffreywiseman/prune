require 'fileutils'

module Prune

  # The configurer is used for configure a custom retention policy for a specified folder by either 
  # editing the retention policy already in place,
  # or by copying the default retention policy from the gem into place in the specified directory, 
  # and then editing it.
  class Configurer

    def initialize( folder, options = {} )
      @config_file = File.join( folder, ".prune" )
    end
    
    def configure
      if File.file? @config_file then
        if File.writable? @config_file then
          edit_config
        else
          puts "Configuration file #{@config_file} exists, but is not writeable; cannot edit configuration."
        end
      elsif File.directory? @config_file
        puts "Configuration file #{@config_file} exists, but is a directory; cannot create or edit configuration file."
      else
        create_config
        edit_config
      end
    end
    
    def has_config?
      File.file? @config_file
    end
    
    def create_config
      FileUtils.cp default_retention, @config_file
      puts "Copied default retention policy to #{@config_file}"
    end
    
    def default_retention
      source_folder = File.dirname( File.expand_path( __FILE__ ) )
      File.join( source_folder, 'default_retention.rb' )
    end
    
    def edit_config
      editor = ENV[ 'VISUAL' ] || ENV[ 'EDITOR' ]
      if editor.nil? then
        puts "No editor defined in 'VISUAL' or 'EDITOR' variables. Edit #{@config_file} in your favorite editor."
      else
        puts "Editing configuration #{@config_file} with #{editor}"
        if system( "#{editor} #{@config_file}" ) then
          puts "Configuration complete."
        else
          puts "Failed to edit file."
        end
      end
    end

  end
  
end
