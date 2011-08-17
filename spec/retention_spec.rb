require 'prune/retention'
#require 'spec/spec_helper'

DAY = 24 * 60 * 60

describe Prune::RetentionPolicy do
  
  SOURCE_DIR = "source_path"
  SOURCE_FILE = "source_file"
  SOURCE_PATH = "#{SOURCE_DIR}/#{SOURCE_FILE}"
  
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
      
      it "should be described as 'Less than 2 Weeks'" do
        subject.describe( :recent ).should include( 'Less than 2 Weeks' )
      end

      it "should invoke action :retain" do
        subject.action( :recent ).should eq( :retain )
      end
    end
  
    describe "created three weeks ago, wednesday" do
      
      it "should be categorized as :remove" do
        File.stub( :directory? ).with( SOURCE_PATH ) { false }
        File.stub( :mtime ).with( SOURCE_PATH ) { weeks_ago( 3, 'Wed' ) }
        subject.categorize( SOURCE_FILE ).should eq( :remove )
      end
      
      it "should be described as 'Older than Two Weeks' and 'Not Friday'" do
        description = subject.describe :remove
        description.should include 'Not Friday'
        description.should include 'Older than 2 Weeks'
      end
      
      it "should invoke action :remove" do 
        subject.action( :remove ).should eq( :remove )
      end
      
    end

    describe "created three weeks ago, friday" do
      
      it "should be categorized as :sparse" do
        File.stub( :directory? ).with( SOURCE_PATH ) { false }
        File.stub( :mtime ).with( SOURCE_PATH ) { weeks_ago( 3, 'Fri' ) }
        subject.categorize( SOURCE_FILE ).should eq( :sparse )
      end
      
      it "should be described as 'Friday Older than 2 Weeks'" do
        subject.describe( :sparse ).should eq( 'Friday Older than 2 Weeks' )
      end
      
      it "should invoke action :remove" do 
        subject.action( :sparse ).should eq( :retain )
      end
      
    end
  
    describe "created three months ago, friday" do

      it "should be categorized as :old" do
        File.stub( :directory? ).with( SOURCE_PATH ) { false }
        File.stub( :mtime ).with( SOURCE_PATH ) { weeks_ago( 12, 'Fri' ) }
        subject.categorize( SOURCE_FILE ).should eq( :old )
      end
      
      it "should be described as 'Friday Older than 2 Months'" do
        subject.describe( :old ).should eq( 'Friday Older than 2 Months' )
      end

      it "should invoke action :remove" do 
        subject.action( :old ).should eq( :archive )
      end

    end
  end

end

def weeks_ago( weeks, weekday )
  sub_weeks = Time.now - ( DAY * 7 * weeks )
  weekday_adjustment = Time.now.wday - Date::ABBR_DAYNAMES.index( weekday )
  sub_weeks - ( weekday_adjustment * DAY )
end