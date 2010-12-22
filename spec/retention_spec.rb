require 'prune/retention'

describe Prune::RetentionPolicy do
  SOURCE_DIR = "source_path"
  SOURCE_FILE = "source_file"
  SOURCE_PATH = "#{SOURCE_DIR}/#{SOURCE_FILE}"
  DAY = 24 * 60 * 60
  subject { Prune::RetentionPolicy.new SOURCE_DIR }

  describe "analyzing a directory" do
    
    it "should be categorized as :dir" do
      File.stub( :directory? ).with( SOURCE_PATH ) { true }
      File.stub( :mtime ).with( SOURCE_PATH ) { Time.now }
      subject.categorize( SOURCE_FILE ).should eq( :dir )
    end
    
    it "should be described as 'Directories'" do
      subject.describe( :dir ).should include( 'Directories' )
    end
    
    it "should invoke action :ignore" do
      subject.action( :dir ).should eq( :ignore )
    end
  end

  describe "analyzing a file" do
    
    describe "created yesterday" do
      
      it "should be categorized as :recent" do
        File.stub( :directory? ).with( SOURCE_PATH ) { false }
        File.stub( :mtime ).with( SOURCE_PATH ) { Time.now - DAY }
        subject.categorize( SOURCE_FILE ).should eq( :recent )
      end
      
      it "should be described as 'Less Than 2 Weeks'" do
        subject.describe( :recent ).should include( 'Less Than 2 Weeks' )
      end

      it "should invoke action :retain" do
        subject.action( :recent ).should eq( :retain )
      end
    end
  
    describe "created three weeks ago, wednesday" do
      pending "categorized as :remove"
      pending "described as 'Non-Friday, Older than Two Weeks'"
      pending "action :remove"
    end

    describe "created three weeks ago, friday" do
      pending "categorized as :sparse"
      pending "described as 'Friday, Older Than Two Weeks'"
      pending "action :retain"
    end
  
    describe "created three months ago, friday" do
      pending "categorized as :old"
      pending "described as 'Older than Two Months'"
      pending "action :archive"
    end
  end

end