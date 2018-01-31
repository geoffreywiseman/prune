require 'prune/archiver'
require 'tmpdir'
require 'rspec'

describe Prune::Archiver do
  SOURCE='/mysql'
  
  before do
    surpress_messages
  end

  describe "with a #{SOURCE} source" do
    DESTINATION = '/mysql-archives'

    subject { Prune::Archiver.new( nil, '/mysql', true ) }

    it "should have #{DESTINATION} destination" do
      expect(subject.destination).to eq( DESTINATION )
    end

    it "should create #{DESTINATION} if does not exist" do
      allow(File).to receive( :exists? ).with( DESTINATION ) { false }
      expect(Dir).to receive( :mkdir ).with( DESTINATION )
      subject.make_destination_dir
    end

    it "should not attempt to create #{DESTINATION} if it exists" do
      allow(File).to receive( :exists? ).with( DESTINATION ) { true }
      expect(Dir).not_to receive( :mkdir )
      subject.make_destination_dir
    end

    context "for May 2011" do
      ARCHIVE_FILE="#{DESTINATION}/archive-May-2011.tar.gz"

      it "should write new archive file in #{DESTINATION} if none exists" do

        # Destination Exists
        allow(File).to receive( :exists? ).with( DESTINATION ) { true }

        # Archive File Exists
        allow(File).to receive( :exists? ).with( ARCHIVE_FILE ) { false }

        # Create Zip File
        archive_file = double "file"
        gz = double "GzipWriter"
        paths = [ "/mysql/a", "/mysql/b", "/mysql/c" ]
        allow(File).to receive( :open ).with( ARCHIVE_FILE, 'wb' ) { archive_file }
        allow(Zlib::GzipWriter).to receive( :new ) { gz }
        expect(Minitar).to receive( :pack ).with( paths, gz )
        expect(File).to receive( :delete ).with( *paths )

        subject.archive "May-2011", ["a", "b", "c"]
      end

      it "should add to existing archive file if it exists" do

        # Destination Exists
        allow(File).to receive( :exists? ).with( DESTINATION ) { true }

        # Archive File Exists
        allow(File).to receive( :exists? ).with( ARCHIVE_FILE ) { true }

        # Should Create Temp Dir
        tmpdir = "/tmp"
        allow(Dir).to receive( :mktmpdir ).and_yield( tmpdir )

        # Should Extract Contents
        archive_file = double "archive file"
        allow(File).to receive( :open ).with( ARCHIVE_FILE, 'rb' ) { archive_file }
        gzr = double "GzipReader"
        allow(Zlib::GzipReader).to receive( :new ) { gzr }
        expect(Minitar).to receive( :unpack ).with( gzr, tmpdir )
        expect(Dir).to receive( :entries ).with( tmpdir ) { ["c", "d"] }
        extracted_paths = [ "/tmp/c", "/tmp/d" ]
        extracted_paths.each { |path| allow(File).to receive( :directory? ).with( path ).and_return( false ) }

        # Should Create Final Archive
        allow(File).to receive( :open ).with( ARCHIVE_FILE, 'wb' ) { archive_file }
        gzw = double "GzipWriter"
        allow(Zlib::GzipWriter).to receive( :new ) { gzw }
        original_paths = [ "/mysql/a", "/mysql/b" ]
        combined_paths = extracted_paths + original_paths
        expect(Minitar).to receive( :pack ).with( combined_paths, gzw )

        # Delete Files
        expect(File).to receive( :delete ).with( *original_paths )

        # Go
        subject.archive "May-2011", ["a", "b"]

      end

    end

    context "and a /mysql/archives destination" do
      subject { Prune::Archiver.new( '/mysql/archives', '/mysql', true ) }

      it "should use the explicit destination" do
        expect(subject.destination).to eq( '/mysql/archives' )
      end

    end

  end

end
