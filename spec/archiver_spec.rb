require 'prune/archiver'

describe Prune::Archiver do
  
  describe "with a /mysql source" do
    DESTINATION = '/mysql-archives'
    
    subject { Prune::Archiver.new( nil, '/mysql', true ) }
    
    it "should have #{DESTINATION} destination" do
      subject.destination.should eq( DESTINATION )
    end
   
    it "should create #{DESTINATION} if does not exist" do
      File.stub( :exists? ).with( DESTINATION ) { false }
      Dir.should_receive( :mkdir ).with( DESTINATION )
      subject.make_destination
    end

    it "should not attempt to create #{DESTINATION} if it exists" do
      File.stub( :exists? ).with( DESTINATION ) { true }
      Dir.should_not_receive( :mkdir )
      subject.make_destination
    end
    
    it "should archive files to #{DESTINATION}" do
      # Destination Exists
      File.stub( :exists? ).with( DESTINATION ) { true }
      
      # Create Zip File
      archive_file = double "file"
      gz = double "GzipWriter"
      paths = [ "/mysql/a", "/mysql/b", "/mysql/c" ]
      File.stub( :open ).with( "#{DESTINATION}/archive-May.tar.gz", 'wb' ) { :archive_file }
      Zlib::GzipWriter.stub( :new ) { gz }
      Minitar.stub( :pack ).with( paths, gz )
      File.stub( :delete ).with( *paths )
      
      subject.archive 5, ["a", "b", "c"] 
    end
    
    describe "and a /mysql/archives destination" do
      subject { Prune::Archiver.new( '/mysql/archives', '/mysql', true ) }
      
      it "should use the explicit destination" do
        subject.destination.should eq( '/mysql/archives' )
      end
    end
  end
  
end