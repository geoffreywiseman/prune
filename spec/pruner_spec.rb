require 'prune/pruner'
require 'prune/retention'
require 'spec_helper'

describe Prune::Pruner do
  
  PRUNE_PATH = '/example/prune/folder'
  subject { Prune::Pruner.new Hash.new }
  
  before( :each ) do 
    @retention_policy = double( "RetentionPolicy" )
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
    
    context "with two files" do
      
      before( :each ) do
        stub_files "beta.txt", "alpha.txt"
        stub_messages
      end
      
      it "should categorize each file in modified order" do
        @retention_policy.should_receive( :categorize ).with( 'beta.txt' ).ordered
        @retention_policy.should_receive( :categorize ).with( 'alpha.txt' ).ordered
        subject.prune PRUNE_PATH
      end
      
      it "should say two files were analyzed" do
        @retention_policy.as_null_object
        subject.prune PRUNE_PATH
        @messages.should include_match( /2 file\(s\) analyzed/ )
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
  
  def stub_files( *files )
    File.stub( :exists? ).with( PRUNE_PATH ) { true }
    File.stub( :directory? ).with( PRUNE_PATH ) { true }
    Dir.stub( :entries ).with( PRUNE_PATH ) { files }
    files.each_index { |index| subject.stub(:test).with( ?M, File.join( PRUNE_PATH, files[index] ) ) { index }  } 
  end
  
  def stub_messages
    @messages = []
    $stdout.stub( :write ) { |message| @messages << message  }
  end
  
end