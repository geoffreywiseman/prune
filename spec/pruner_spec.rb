require 'prune'
require 'spec_helper'
require 'rspec'

describe Prune::Pruner do

  PRUNE_PATH = '/example/prune/folder'
  subject { Prune::Pruner.new Hash.new }

  before( :each ) do
    @categories = [ Category.new( "Unmatched Files", :retain, true ) ]
    @retention_policy = double( "RetentionPolicy" )
    @retention_policy.stub( :categories ) { @categories }
    Prune::RetentionPolicy.stub( :new ) { @retention_policy }
  end

  context "w/o prompt" do
    before( :each ) do
      subject.options[:prompt]=false
    end

    it "should not attempt to process folder that does not exist" do
      File.stub( :exists? ).with( PRUNE_PATH ) { false }
      Dir.should_not_receive( :foreach )
      $stdout.should_receive( :write ).with( /ERROR: Cannot find folder/ )
      subject.prune( PRUNE_PATH )
    end

    context "with no files" do

      before( :each ) do
        stub_files
        stub_messages
        subject.prune PRUNE_PATH
      end

      it "should not invoke the retention policy" do
        @retention_policy.should_not_receive( :categorize )
      end

      it "should print 'Analyzing #{PRUNE_PATH}'" do
        @messages.should include("Analyzing '#{PRUNE_PATH}':\n")
      end

      it "should say no action was required" do
        @messages.should include("No actions necessary.\n")
      end

      it "should say no files were analyzed" do
        @messages.should include_match( /0 file\(s\) analyzed/ )
      end

    end

    context "with just a .prune file" do

      before( :each ) do
        stub_files [ ".prune", '.', '..' ]
        stub_messages
        subject.prune PRUNE_PATH
      end

      it "should not invoke the retention policy" do
        @retention_policy.should_not_receive( :categorize )
      end

      it "should print 'Analyzing #{PRUNE_PATH}'" do
        @messages.should include("Analyzing '#{PRUNE_PATH}':\n")
      end

      it "should say no action was required" do
        @messages.should include("No actions necessary.\n")
      end

      it "should say no files were analyzed" do
        @messages.should include_match( /0 file\(s\) analyzed/ )
      end

    end


    context "with three files" do
      ONE_DAY = 86400

      before( :each ) do
        stub_files "beta.txt" => Time.now - ONE_DAY, "alpha.txt" => Time.now - 3*ONE_DAY, "gamma.txt" => Time.now
        stub_messages
      end

      it "should categorize each file in modified order" do
        @retention_policy.should_receive( :categorize ).with( 'alpha.txt' ).ordered
        @retention_policy.should_receive( :categorize ).with( 'beta.txt' ).ordered
        @retention_policy.should_receive( :categorize ).with( 'gamma.txt' ).ordered
        subject.prune PRUNE_PATH
      end

      it "should say three files were analyzed" do
        @retention_policy.as_null_object
        subject.prune PRUNE_PATH
        @messages.should include_match( /3 file\(s\) analyzed/ )
      end

    end

    context "with file categorized as :remove" do
      FILENAME = 'delete-me.txt'
      
      before( :each ) do
        stub_messages
        
        stub_files FILENAME
        
        category = double( category )
        category.stub( :description ) { "Old" }
        category.stub( :action ) { :remove }
        category.stub( :quiet? ) { false }
        @retention_policy.should_receive( :categorize ).with( FILENAME ) { category }
      end
      
      it "should delete file" do
        File.should_receive( :delete ).with( File.join( PRUNE_PATH, FILENAME ) )
        subject.prune PRUNE_PATH
      end
      
      it "should display file deleted message" do
        File.stub( :delete )
        subject.prune PRUNE_PATH
        @messages.should include_match( /file\(s\) deleted/ )
      end
    end
      
    context "with no files categorized as archive" do
        
      before do
        subject.options[:archive] = true
        stub_files
        stub_messages
        
        category = double( "category" )
        category.stub( :action ) { :archive }
        category.stub( :description ) { "Archive" }
        category.stub( :quiet? ) { false }
        
        @retention_policy.stub( :categories ) { [ category ]}
      end
        
      it "should indicate no archive necessary" do
        subject.prune PRUNE_PATH
        puts "Messages: #{@messages}"
        @messages.should include_match( /No files categorized for archival/ )
      end
        
    end

    context "with files categorized as :archive" do
      let!(:files) { [ 'one.tar.gz', 'two.tar.gz', 'three.tar.gz' ] }

      before do
        subject.options[:archive] = true
        stub_files files
        stub_messages

        category = double( "category" )
        @retention_policy.stub( :categorize ) { category }
        category.stub( :action ) { :archive }
        category.stub( :description ) { "Ancient" }
        category.stub( :quiet? ) { false }
      end

      it "should archive files in groups" do
        grouper = double( "Grouper" )
        Prune::Grouper.stub( :new ) { grouper }
        grouper.should_receive( :group ).with( PRUNE_PATH, files )
        grouper.should_receive( :archive ) { "2 Archives created." }

        subject.prune PRUNE_PATH
      end
      
      it "should display message if archive option disabled" do
        subject.options[:archive] = false
        subject.prune PRUNE_PATH
        @messages.should include_match( /Archive option disabled/ )
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
        subject.display_categories( { Category.new( "Empty Category", :retain ) => [] } )
        @messages.should include_match( /Empty Category/ )
      end
        
      it "should display quiet categories" do
        subject.display_categories( { Category.new( "Quiet Category", :retain, true ) => [ 'quiet.txt' ] } )
        @messages.should include_match( /Quiet Category/ )
      end
      
      it "should display categories with files" do
        subject.display_categories( { Category.new( "Normal Category", :retain ) => [ 'normal.txt' ] } )
        @messages.should include_match( /Normal Category/ )
      end
    end
    
    describe "when not verbose" do
      
      before do
        subject.options[:verbose]=false
      end
        
      it "should not display empty categories" do
        subject.display_categories( { Category.new( "Empty Category", :retain, true ) => [] } )
        @messages.should_not include_match( /Empty Category/ )
      end
      
      it "should not display quiet categories" do
        subject.display_categories( { Category.new( "Quiet Category", :retain, true ) => [ 'shhh.txt' ] } )
        @messages.should_not include_match( /Quiet Category/ )
      end
      
      it "should display categories with files" do
        subject.display_categories( { Category.new( "Normal Category", :retain ) => [ 'normal.txt' ] } )
        @messages.should include_match( /Normal Category/ )
      end

    end
  end

  describe "Confirmation Prompt" do
    before( :each ) do
      subject.options[:prompt]=false
    end

    it "should interpret 'Y' as true" do
      expect_prompt_with_response( "Y\n")
      subject.prompt.should be_true
    end

    it "should interpret 'Y ' as true" do
      expect_prompt_with_response("Y \n")
      subject.prompt.should be_true
    end

    it "should interpret ' Y' as true" do
      expect_prompt_with_response(" Y\n")
      subject.prompt.should be_true
    end

    it "should interpret ' Y ' as true" do
      expect_prompt_with_response(" Y \n")
      subject.prompt.should be_true
    end

    it "should interpret 'y' as true" do
      expect_prompt_with_response("y\n")
      subject.prompt.should be_true
    end

    it "should interpret 'yes' as true" do
      expect_prompt_with_response("yes\n")
      subject.prompt.should be_true
    end

    it "should interpret 'no' as false" do
      expect_prompt_with_response("no\n")
      subject.prompt.should be_false
    end

    it "should interpret 'n' as false" do
      expect_prompt_with_response("n\n")
      subject.prompt.should be_false
    end

    it "should interpret 'N' as false" do
      expect_prompt_with_response("N\n")
      subject.prompt.should be_false
    end

    it "should interpret 'q' as false" do
      expect_prompt_with_response("q\n")
      subject.prompt.should be_false
    end

    def expect_prompt_with_response( response )
      $stdout.should_receive( :write ).with( /Proceed?/ )
      STDIN.stub(:gets) { response }
    end

  end

  def stub_files( files = nil )
    File.stub( :exists? ).with( PRUNE_PATH ) { true }
    File.stub( :directory? ).with( PRUNE_PATH ) { true }
    case files
    when nil
      Dir.stub( :entries ).with( PRUNE_PATH ) { Array.new }
    when String
      subject.stub(:test).with( ?M, File.join( PRUNE_PATH, files ) ) { Time.now }
      Dir.stub( :entries ).with( PRUNE_PATH ) { [ files ] }
    when Array
      files.each_index { |index| subject.stub(:test).with( ?M, File.join( PRUNE_PATH, files[index] ) ) { index }  }
      Dir.stub( :entries ).with( PRUNE_PATH ) { files }
    when Hash
      files.each_key { |key| subject.stub(:test).with( ?M, File.join( PRUNE_PATH, key ) ) { files[key] } }
      Dir.stub( :entries ).with( PRUNE_PATH ) { files.keys }
    else
      raise "Don't know how to stub files for #{files.class}"
    end
  end

end
