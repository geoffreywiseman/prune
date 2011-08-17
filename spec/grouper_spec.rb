require 'prune/grouper'
require 'prune/retention'
require 'spec_helper'
require 'rspec'

describe "Prune::Grouper" do
  
  GROUP_PATH = '/example/prune/folder'
  before( :each ) do
     @archiver = double( "Archiver" )
     @grouper = Prune::Grouper.new( @archiver )
  end

  context "w/o files" do
  
    it "should not archive" do
      @archiver.should_not_receive( :archive )
      @grouper.group( GROUP_PATH, [] ).archive
    end
    
  end
  
  context "with files" do
    
    it "should archive files" do
      files = mock_files( Date.new(2011,01,01) )
      @archiver.should_receive( :archive )
      @grouper.group( GROUP_PATH, files ).archive
    end
    
    it "should specify month and year" do
      files = mock_files( Date.new(2008,03,01) )
      @archiver.should_receive( :archive ).with( "Mar-2008", files )
      @grouper.group( GROUP_PATH, files ).archive
    end
    
    it "should combine files with same month/year" do 
      files = mock_files( Date.new(2008,03,01), Date.new(2008,03,02) )
      @archiver.should_receive( :archive ).with( "Mar-2008", files )
      @grouper.group( GROUP_PATH, files ).archive
    end
    
    it "should not combine files with same month, different year" do
      files = mock_files( Date.new(2008,03,01), Date.new(2009,03,01) )
      @archiver.should_receive( :archive ).with( "Mar-2008", [files.first] )
      @archiver.should_receive( :archive ).with( "Mar-2009", [files.last] )
      @grouper.group( GROUP_PATH, files ).archive
    end
    
  end
  
  def mock_files( *dates )
    files = []
    dates.map do |item|
      month_name = Date::ABBR_MONTHNAMES[item.month]
      file_name = "file-#{month_name}-#{item.year}.sql"
      File.stub( :mtime ).with( "#{GROUP_PATH}/#{file_name}" ) { item }
      files << file_name
    end
    return files;
  end
      
end