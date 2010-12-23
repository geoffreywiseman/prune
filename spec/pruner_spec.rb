require 'prune/pruner'

describe Prune::Pruner do
  
  @options = { :verbose => true, :prompt => true }
  subject { Prune::Pruner.new @options }
  
  it "should not attempt to process folder that does not exist" do
    fake_path = '/fake/folder/path'
    File.stub( :exists? ).with( fake_path ) { false }
    Dir.should_not_receive( :foreach )
    $stdout.should_receive( :write ).with( /ERROR: Cannot find folder/ )
    subject.prune( fake_path )
  end
  
  describe "Confirmation Prompt" do
    
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
  
end