module Prune
  class Grouper

    def initialize( archiver )
      @groups = Hash.new{ |h,k| h[k] = [] }
      @archiver = archiver
    end

    def group( folder_name, files )
      files.each do |file|
        mtime = File.mtime( File.join( folder_name, file ) )
        month_name = Date::ABBR_MONTHNAMES[ mtime.month ]
        group_name = "#{month_name}-#{mtime.year}"
        @groups[ group_name ] << file
      end
      return self
    end

    def archive
      @groups.each_pair do |month,files|
        @archiver.archive( month, files )
      end
      sizes = @groups.values.map { |x| x.size }.join( ', ' )
      "#{@groups.size} archive(s) created (#{sizes} file(s), respectively)"
    end
  end
end
