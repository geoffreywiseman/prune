require 'prune'
require 'spec_helper'
require 'rspec'

describe Prune::Pruner do

  PRUNE_PATH = '/example/prune/folder'
  subject { Prune::Pruner.new Hash.new }

  before( :each ) do
    @categories = [ Prune::Category.new( "Unmatched Files", :retain, true ) ]
    @retention_policy = double( "RetentionPolicy" )
    allow(@retention_policy).to receive( :categories ) { @categories }
    allow(Prune::RetentionPolicy).to receive( :new ) { @retention_policy }
  end

  context "w/o prompt" do
    before( :each ) do
      subject.options[:prompt]=false
    end

    it "should not attempt to process folder that does not exist" do
      allow(File).to receive( :exists? ).with( PRUNE_PATH ) { false }
      expect(Dir).not_to receive( :foreach )
      expect($stdout).to receive( :write ).with( /ERROR: Cannot find folder/ )
      subject.prune( PRUNE_PATH )
    end

    context "with no files" do

      before( :each ) do
        stub_files
        stub_messages
        subject.prune PRUNE_PATH
      end

      it "should not invoke the retention policy" do
        expect(@retention_policy).not_to receive( :categorize )
      end

      it "should print 'Analyzing #{PRUNE_PATH}'" do
        expect(@messages).to include("Analyzing '#{PRUNE_PATH}':\n")
      end

      it "should say no action was required" do
        expect(@messages).to include("No actions necessary.\n")
      end

      it "should say no files were analyzed" do
        expect(@messages).to include_match( /0 file\(s\) analyzed/ )
      end

    end

    context "with just a .prune file" do

      before( :each ) do
        stub_files [ ".prune", '.', '..' ]
        stub_messages
        subject.prune PRUNE_PATH
      end

      it "should not invoke the retention policy" do
        expect(@retention_policy).not_to receive( :categorize )
      end

      it "should print 'Analyzing #{PRUNE_PATH}'" do
        expect(@messages).to include("Analyzing '#{PRUNE_PATH}':\n")
      end

      it "should say no action was required" do
        expect(@messages).to include("No actions necessary.\n")
      end

      it "should say no files were analyzed" do
        expect(@messages).to include_match( /0 file\(s\) analyzed/ )
      end

    end


    context "with three files" do
      ONE_DAY = 86400

      before( :each ) do
        stub_files "beta.txt" => Time.now - ONE_DAY, "alpha.txt" => Time.now - 3*ONE_DAY, "gamma.txt" => Time.now
        stub_messages
      end

      it "should categorize each file in modified order" do
        expect(@retention_policy).to receive( :categorize ).with( 'alpha.txt' ).ordered
        expect(@retention_policy).to receive( :categorize ).with( 'beta.txt' ).ordered
        expect(@retention_policy).to receive( :categorize ).with( 'gamma.txt' ).ordered
        subject.prune PRUNE_PATH
      end

      it "should say three files were analyzed" do
        @retention_policy.as_null_object
        subject.prune PRUNE_PATH
        expect(@messages).to include_match( /3 file\(s\) analyzed/ )
      end

    end

    context "with file categorized as :remove" do
      FILENAME = 'delete-me.txt'
      
      before( :each ) do
        stub_messages
        
        stub_files FILENAME
        
        category = double( category )
        allow(category).to receive( :description ) { "Old" }
        allow(category).to receive( :action ) { :remove }
        allow(category).to receive( :quiet? ) { false }
        expect(@retention_policy).to receive( :categorize ).with( FILENAME ) { category }
      end
      
      it "should delete file" do
        expect(FileUtils).to receive( :remove_entry ).with( File.join( PRUNE_PATH, FILENAME ), true ) { 1 }
        subject.prune PRUNE_PATH
      end
      
      it "should display file deleted message" do
        expect(FileUtils).to receive( :remove_entry ).with( File.join( PRUNE_PATH, FILENAME ), true ) { 1 }
        subject.prune PRUNE_PATH
        expect(@messages).to include_match( /1 file\(s\) deleted/ )
      end

      it "should display failed deletion mesage" do
        expect(FileUtils).to receive( :remove_entry ).with( File.join( PRUNE_PATH, FILENAME ), true ) { 0 }
        subject.prune PRUNE_PATH
        expect(@messages).to include_match( /0 file\(s\) deleted, 1 file\(s\) could not be deleted/ )
      end

    end
      
    context "with no files categorized as archive" do
        
      before do
        subject.options[:archive] = true
        stub_files
        stub_messages
        
        category = double( "category" )
        allow(category).to receive( :action ) { :archive }
        allow(category).to receive( :description ) { "Archive" }
        allow(category).to receive( :quiet? ) { false }
        
        allow(@retention_policy).to receive( :categories ) { [ category ]}
      end
        
      it "should indicate no archive necessary" do
        subject.prune PRUNE_PATH
        puts "Messages: #{@messages}"
        expect(@messages).to include_match( /No files categorized for archival/ )
      end
        
    end

    context "with files categorized as :archive" do
      let!(:files) { [ 'one.tar.gz', 'two.tar.gz', 'three.tar.gz' ] }

      before do
        subject.options[:archive] = true
        stub_files files
        stub_messages

        category = double( "category" )
        allow(@retention_policy).to receive( :categorize ) { category }
        allow(category).to receive( :action ) { :archive }
        allow(category).to receive( :description ) { "Ancient" }
        allow(category).to receive( :quiet? ) { false }
      end

      it "should archive files in groups" do
        grouper = double( "Grouper" )
        allow(Prune::Grouper).to receive( :new ) { grouper }
        expect(grouper).to receive( :group ).with( PRUNE_PATH, files )
        expect(grouper).to receive( :archive ) { "2 Archives created." }

        subject.prune PRUNE_PATH
      end
      
      it "should display message if archive option disabled" do
        subject.options[:archive] = false
        subject.prune PRUNE_PATH
        expect(@messages).to include_match( /Archive option disabled/ )
      end
    end
  
  end
  
  describe "when displaying categories" do
      
    before do
      stub_messages
    end
      
    describe "when verbose" do
      
      before do
        subject.options[:verbose]=true
      end
        
      it "should display empty categories" do
        subject.display_categories( { Prune::Category.new( "Empty Category", :retain ) => [] } )
        expect(@messages).to include_match( /Empty Category/ )
      end
        
      it "should display quiet categories" do
        subject.display_categories( { Prune::Category.new( "Quiet Category", :retain, true ) => [ 'quiet.txt' ] } )
        expect(@messages).to include_match( /Quiet Category/ )
      end
      
      it "should display categories with files" do
        subject.display_categories( { Prune::Category.new( "Normal Category", :retain ) => [ 'normal.txt' ] } )
        expect(@messages).to include_match( /Normal Category/ )
      end
    end
    
    describe "when not verbose" do
      
      before do
        subject.options[:verbose]=false
      end
        
      it "should not display empty categories" do
        subject.display_categories( { Prune::Category.new( "Empty Category", :retain, true ) => [] } )
        expect(@messages).not_to include_match( /Empty Category/ )
      end
      
      it "should not display quiet categories" do
        subject.display_categories( { Prune::Category.new( "Quiet Category", :retain, true ) => [ 'shhh.txt' ] } )
        expect(@messages).not_to include_match( /Quiet Category/ )
      end
      
      it "should display categories with files" do
        subject.display_categories( { Prune::Category.new( "Normal Category", :retain ) => [ 'normal.txt' ] } )
        expect(@messages).to include_match( /Normal Category/ )
      end

    end
  end

  describe "Confirmation Prompt" do
    before( :each ) do
      subject.options[:prompt]=false
    end

    it "should interpret 'Y' as true" do
      expect_prompt_with_response( "Y\n")
      expect(subject.prompt).to be_truthy
    end

    it "should interpret 'Y ' as true" do
      expect_prompt_with_response("Y \n")
      expect(subject.prompt).to be_truthy
    end

    it "should interpret ' Y' as true" do
      expect_prompt_with_response(" Y\n")
      expect(subject.prompt).to be_truthy
    end

    it "should interpret ' Y ' as true" do
      expect_prompt_with_response(" Y \n")
      expect(subject.prompt).to be_truthy
    end

    it "should interpret 'y' as true" do
      expect_prompt_with_response("y\n")
      expect(subject.prompt).to be_truthy
    end

    it "should interpret 'yes' as true" do
      expect_prompt_with_response("yes\n")
      expect(subject.prompt).to be_truthy
    end

    it "should interpret 'no' as false" do
      expect_prompt_with_response("no\n")
      expect(subject.prompt).to be_falsey
    end

    it "should interpret 'n' as false" do
      expect_prompt_with_response("n\n")
      expect(subject.prompt).to be_falsey
    end

    it "should interpret 'N' as false" do
      expect_prompt_with_response("N\n")
      expect(subject.prompt).to be_falsey
    end

    it "should interpret 'q' as false" do
      expect_prompt_with_response("q\n")
      expect(subject.prompt).to be_falsey
    end

    def expect_prompt_with_response( response )
      expect($stdout).to receive( :write ).with( /Proceed?/ )
      allow(STDIN).to receive(:gets) { response }
    end

  end

  def stub_files( files = nil )
    allow(File).to receive( :exists? ).with( PRUNE_PATH ) { true }
    allow(File).to receive( :directory? ).with( PRUNE_PATH ) { true }
    case files
    when nil
      allow(Dir).to receive( :entries ).with( PRUNE_PATH ) { Array.new }
    when String
      allow(subject).to receive(:test).with( ?M, File.join( PRUNE_PATH, files ) ) { Time.now }
      allow(Dir).to receive( :entries ).with( PRUNE_PATH ) { [ files ] }
    when Array
      files.each_index { |index| allow(subject).to receive(:test).with( ?M, File.join( PRUNE_PATH, files[index] ) ) { index }  }
      allow(Dir).to receive( :entries ).with( PRUNE_PATH ) { files }
    when Hash
      files.each_key { |key| allow(subject).to receive(:test).with( ?M, File.join( PRUNE_PATH, key ) ) { files[key] } }
      allow(Dir).to receive( :entries ).with( PRUNE_PATH ) { files.keys }
    else
      raise "Don't know how to stub files for #{files.class}"
    end
  end

end
