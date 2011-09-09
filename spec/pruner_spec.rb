require 'prune/pruner'
require 'prune/retention'
require 'prune/grouper'
require 'prune/archiver'
require 'spec_helper'
require 'rspec'

describe Prune::Pruner do

  PRUNE_PATH = '/example/prune/folder'
  subject { Prune::Pruner.new Hash.new }

  before( :each ) do
    @retention_policy = double( "RetentionPolicy" )
    @retention_policy.stub( :categories ) { [] }
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
      it "should delete file" do
        filename = 'delete-me.txt'
        stub_files filename
        
        category = double( category )
        category.stub( :description ) { "Old" }
        category.stub( :action ) { :remove }
        category.stub( :quiet? ) { false }
        
        @retention_policy.should_receive( :categorize ).with( filename ) { category }
        File.should_receive( :delete ).with( File.join( PRUNE_PATH, filename ) )
        subject.prune PRUNE_PATH
      end
    end

    context "with files categorized as :archive" do
      let!(:files) { [ 'one.tar.gz', 'two.tar.gz', 'three.tar.gz' ] }

      before do
        subject.options[:archive] = true
        stub_files files
      end

      it "should archive files in groups" do
        category = double( "category" )
        @retention_policy.stub( :categorize ) { category }
        category.stub( :action ) { :archive }
        category.stub( :description ) { "Ancient" }
        category.stub( :quiet? ) { false }
        
        grouper = double( "Grouper" )
        Prune::Grouper.stub( :new ) { grouper }
        grouper.should_receive( :group ).with( PRUNE_PATH, files )
        grouper.should_receive( :archive ) { "2 Archives created." }

        subject.prune PRUNE_PATH
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

  def stub_messages
    @messages = []
    $stdout.stub( :write ) { |message| @messages << message  }
  end

end
