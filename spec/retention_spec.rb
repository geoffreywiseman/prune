require 'prune/retention'
require 'prune/category'
require 'rspec'
require 'spec/spec_helper'

DAY = 24 * 60 * 60

describe Prune::RetentionPolicy do

  SOURCE_DIR = "source_path"
  SOURCE_FILE = "source_file"
  SOURCE_PATH = "#{SOURCE_DIR}/#{SOURCE_FILE}"

  subject { Prune::RetentionPolicy.new SOURCE_DIR }

  describe "default retention policy" do
  
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

end

def weeks_ago( weeks, weekday )
  sub_weeks = Time.now - ( DAY * 7 * weeks )
  weekday_adjustment = Time.now.wday - Date::ABBR_DAYNAMES.index( weekday )
  sub_weeks - ( weekday_adjustment * DAY )
end
