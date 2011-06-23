require 'prune/archiver'
require 'tmpdir'

describe Prune::Archiver do
  SOURCE='/mysql'
  
  describe "with a #{SOURCE} source" do
    DESTINATION = '/mysql-archives'
    
    subject { Prune::Archiver.new( nil, '/mysql', true ) }
    
    it "should have #{DESTINATION} destination" do
      subject.destination.should eq( DESTINATION )
    end
   
    it "should create #{DESTINATION} if does not exist" do
      File.stub( :exists? ).with( DESTINATION ) { false }
      Dir.should_receive( :mkdir ).with( DESTINATION )
      subject.make_destination_dir
    end

    it "should not attempt to create #{DESTINATION} if it exists" do
      File.stub( :exists? ).with( DESTINATION ) { true }
      Dir.should_not_receive( :mkdir )
      subject.make_destination_dir
    end
    
    context "for May 2011" do
      ARCHIVE_FILE="#{DESTINATION}/archive-May-2011.tar.gz"
    
      it "should write new archive file in #{DESTINATION} if none exists" do
        
        # Destination Exists
        File.stub( :exists? ).with( DESTINATION ) { true }
        
        # Archive File Exists
        File.stub( :exists? ).with( ARCHIVE_FILE ) { false }
      
        # Create Zip File
        archive_file = double "file"
        gz = double "GzipWriter"
        paths = [ "/mysql/a", "/mysql/b", "/mysql/c" ]
        File.stub( :open ).with( ARCHIVE_FILE, 'wb' ) { archive_file }
        Zlib::GzipWriter.stub( :new ) { gz }
        Minitar.should_receive( :pack ).with( paths, gz )
        File.should_receive( :delete ).with( *paths )
      
        subject.archive "May-2011", ["a", "b", "c"] 
      end
    
      it "should add to existing archive file if it exists" do

        # Destination Exists
        File.stub( :exists? ).with( DESTINATION ) { true }
        
        # Archive File Exists
        File.stub( :exists? ).with( ARCHIVE_FILE ) { true }
      
        # Should Create Temp Dir
        tmpdir = "/tmp"
        Dir.stub( :mktmpdir ).and_yield( tmpdir )
        
        # Should Extract Contents
        archive_file = double "archive file"
        File.stub( :open ).with( ARCHIVE_FILE, 'rb' ) { archive_file }
        gzr = double "GzipReader"
        Zlib::GzipReader.stub( :new ) { gzr }
        Minitar.should_receive( :unpack ).with( gzr, tmpdir )
        Dir.should_receive( :entries ).with( tmpdir ) { ["c", "d"] }
        extracted_paths = [ "/tmp/c", "/tmp/d" ]
        extracted_paths.each { |path| File.stub( :directory? ).with( path ).and_return( false ) }
        
        # Should Create Final Archive
        File.stub( :open ).with( ARCHIVE_FILE, 'wb' ) { archive_file }
        gzw = double "GzipWriter"
        Zlib::GzipWriter.stub( :new ) { gzw }
        original_paths = [ "/mysql/a", "/mysql/b" ]
        combined_paths = extracted_paths + original_paths
        Minitar.should_receive( :pack ).with( combined_paths, gzw )
        
        # Delete Files
        File.should_receive( :delete ).with( *original_paths )
      
        # Go
        subject.archive "May-2011", ["a", "b"] 

      end
      
    end
    
    context "and a /mysql/archives destination" do
      subject { Prune::Archiver.new( '/mysql/archives', '/mysql', true ) }
      
      it "should use the explicit destination" do
        subject.destination.should eq( '/mysql/archives' )
      end
      
    end
    
  end
  
end