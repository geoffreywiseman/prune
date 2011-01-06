require 'prune/pruner'
require 'prune/retention'

describe Prune::Pruner do
  
  PATH = '/example/prune/folder'
  subject { Prune::Pruner.new Hash.new }
  
  before( :each ) do 
    @retention_policy = double
    Prune::RetentionPolicy.stub( :new ) { @retention_policy }
  end  
  
  context "w/o prompt" do
    before( :each ) do
      subject.options[:prompt]=false
    end
        
    it "should not attempt to process folder that does not exist" do
      File.stub( :exists? ).with( PATH ) { false }
      Dir.should_not_receive( :foreach )
      $stdout.should_receive( :write ).with( /ERROR: Cannot find folder/ )
      subject.prune( PATH )
    end
    
    context "with no files" do
      
      before( :each ) do
        stub_files
      end
      
      it "should not invoke the retention policy" do
        @retention_policy.should_not_receive( :categorize )
        subject.prune PATH
      end

      describe "printed messages" do
        before( :all ) do
          stub_files
          @messages = []
          $stdout.stub( :write ) { |message| @messages << message  }
          subject.prune PATH
        end
        
        it "should say no action was required" do
          @messages.should include("Analyzing '#{PATH}':\n")
        end

        it "should say no files were analyzed" do
          @messages.should grep( /0 file\(s\) analyzed/ )
        end

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
  
  def stub_files(*files)
    File.stub( :exists? ).with( PATH ) { true }
    File.stub( :directory? ).with( PATH ) { true }
    Dir.stub( :foreach ).with( PATH ) { files }
  end
  
end

RSpec::Matchers.define :grep do |expected|
  match do |actual|
    actual.grep( expected )
  end
end