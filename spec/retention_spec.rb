require 'prune/retention'
require 'prune/category'
require 'rspec'
require 'spec_helper'

DAY = 24 * 60 * 60

describe Prune::RetentionPolicy do

  SOURCE_DIR = "source_path"
  SOURCE_FILE = "source_file"
  SOURCE_PATH = "#{SOURCE_DIR}/#{SOURCE_FILE}"

  before do
    surpress_messages
  end

  describe "default retention policy" do
    
    subject { Prune::RetentionPolicy.new SOURCE_DIR }

    it "should return categories in dsl order" do
      cats = subject.categories
      cats.shift.description.should include( "Ignoring directories" )
      cats.shift.description.should include( "from the Last Two Weeks" )
      cats.shift.description.should include( "Retaining 'Friday'" )
      cats.shift.description.should include( "Removing 'Non-Friday'" )
      cats.shift.description.should include( "Archiving" )
      cats.should be_empty
    end
  
    describe "analyzing a directory" do
      let( :dircat ) do
        File.stub( :directory? ).with( SOURCE_PATH ) { true }
        File.stub( :mtime ).with( SOURCE_PATH ) { Time.now }
        subject.categorize( SOURCE_FILE )
      end
      
      
      it "should be categorized as 'Ignoring directories'" do
        dircat.description.should eq( "Ignoring directories" )
      end

      it "should invoke action :ignore" do
        dircat.action.should eq( :ignore )
      end
    end

    describe "analyzing a file" do

      describe "created yesterday" do
        
        let( :yestercat ) do
          File.stub( :directory? ).with( SOURCE_PATH ) { false }
          File.stub( :mtime ).with( SOURCE_PATH ) { Time.now - DAY }
          subject.categorize( SOURCE_FILE )
        end

        it "should be categorized as '... Last Two Weeks'" do
          yestercat.description.should include( 'Last Two Weeks' )
        end

        it "should invoke action :retain" do
          yestercat.action.should eq( :retain )
        end
      end

      describe "created three weeks ago, wednesday" do

        let( :weeksago ) do
          File.stub( :directory? ).with( SOURCE_PATH ) { false }
          File.stub( :mtime ).with( SOURCE_PATH ) { weeks_ago( 3, 'Wed' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Older than Two Weeks' and 'Non-Friday'" do
          weeksago.description.should include 'Non-Friday'
          weeksago.description.should include 'Older than Two Weeks'
        end

        it "should invoke action :remove" do
          weeksago.action.should eq( :remove )
        end

      end

      describe "created three weeks ago, friday" do

        let( :weeksagofriday ) do
          File.stub( :directory? ).with( SOURCE_PATH ) { false }
          File.stub( :mtime ).with( SOURCE_PATH ) { weeks_ago( 3, 'Fri' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Friday files', 'Older than Two Weeks'" do
          weeksagofriday.description.should include( "'Friday' files" )
          weeksagofriday.description.should include( 'Older than Two Weeks' )
        end

        it "should invoke action :remove" do
          weeksagofriday.action.should eq( :retain )
        end

      end

      describe "created three months ago, friday" do

        let( :oldfriday ) do
          File.stub( :directory? ).with( SOURCE_PATH ) { false }
          File.stub( :mtime ).with( SOURCE_PATH ) { weeks_ago( 12, 'Fri' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Older than Two Months'" do
          oldfriday.description.should include( 'Older than Two Months' )
        end

        it "should invoke action :archive" do
          oldfriday.action.should eq( :archive )
        end

      end

      describe "created three months ago, wednesday" do

        let( :oldwednesday ) do
          File.stub( :directory? ).with( SOURCE_PATH ) { false }
          File.stub( :mtime ).with( SOURCE_PATH ) { weeks_ago( 12, 'Wed' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Non-Friday files', 'Older than Two Weeks'" do
          oldwednesday.description.should include( "'Non-Friday' files" )
          oldwednesday.description.should include( "Older than Two Weeks" )
        end

        it "should invoke action :remove" do
          oldwednesday.action.should eq( :remove )
        end

      end
    end
  end
  
  describe "filename-based retention policy" do
    
    subject { Prune::RetentionPolicy.new SOURCE_DIR, load_dsl: false }
    
    before do
      subject.preprocess do |file|
        if file.name =~ /-(\d{8})./ then
          file.fyear = Date.parse($1).year
        else
          file.fyear = nil
        end
      end
      subject.category "Ignoring" do 
        match { |f| File.directory?(f.name) || f.fyear.nil? }
        ignore
        quiet
      end
      subject.category "2010" do
        match { |f| File.file?(f.name) && f.fyear == 2010  }
        retain
      end
      subject.category "2011" do
        match { |f| File.file?(f.name) && f.fyear == 2011  }
        retain
      end
    end
    
    it "should ignore directories" do
      subject.categorize( "." ).description.should eq( "Ignoring" )
    end
    
    it "should ignore files not matching pattern" do
      File.stub(:file?) { true }
      subject.categorize( 'readme.txt' ).description.should eq( 'Ignoring' )
    end
    
    describe "with a file named with 20101001" do
      before do
        File.stub(:directory?) { false }
        File.stub(:file?) { true }
      end
      
      it "should categorize as 2010" do
        subject.categorize( 'mysql-prod-20101001.sql.gz' ).description.should eq( '2010' )
      end
    end

    describe "with a file named with 20110215" do
      before do
        File.stub(:directory?) { false }
        File.stub(:file?) { true }
      end
      
      it "should categorize as 2011" do
        subject.categorize( 'subversion-20110215.tar.gz' ).description.should eq( '2011' )
      end
    end
  end

end

def weeks_ago( weeks, weekday )
  sub_weeks = Time.now - ( DAY * 7 * weeks )
  weekday_adjustment = Time.now.wday - Date::ABBR_DAYNAMES.index( weekday )
  sub_weeks - ( weekday_adjustment * DAY )
end
