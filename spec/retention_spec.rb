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
      expect(cats.shift.description).to include( "Ignoring directories" )
      expect(cats.shift.description).to include( "from the Last Two Weeks" )
      expect(cats.shift.description).to include( "Retaining 'Friday'" )
      expect(cats.shift.description).to include( "Removing 'Non-Friday'" )
      expect(cats.shift.description).to include( "Archiving" )
      expect(cats).to be_empty
    end
  
    describe "analyzing a directory" do
      let( :dircat ) do
        allow(File).to receive( :directory? ).with( SOURCE_PATH ) { true }
        allow(File).to receive( :mtime ).with( SOURCE_PATH ) { Time.now }
        subject.categorize( SOURCE_FILE )
      end
      
      
      it "should be categorized as 'Ignoring directories'" do
        expect(dircat.description).to eq( "Ignoring directories" )
      end

      it "should invoke action :ignore" do
        expect(dircat.action).to eq( :ignore )
      end
    end

    describe "analyzing a file" do

      describe "created yesterday" do
        
        let( :yestercat ) do
          allow(File).to receive( :directory? ).with( SOURCE_PATH ) { false }
          allow(File).to receive( :mtime ).with( SOURCE_PATH ) { Time.now - DAY }
          subject.categorize( SOURCE_FILE )
        end

        it "should be categorized as '... Last Two Weeks'" do
          expect(yestercat.description).to include( 'Last Two Weeks' )
        end

        it "should invoke action :retain" do
          expect(yestercat.action).to eq( :retain )
        end
      end

      describe "created three weeks ago, wednesday" do

        let( :weeksago ) do
          allow(File).to receive( :directory? ).with( SOURCE_PATH ) { false }
          allow(File).to receive( :mtime ).with( SOURCE_PATH ) { weeks_ago( 3, 'Wed' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Older than Two Weeks' and 'Non-Friday'" do
          expect(weeksago.description).to include 'Non-Friday'
          expect(weeksago.description).to include 'Older than Two Weeks'
        end

        it "should invoke action :remove" do
          expect(weeksago.action).to eq( :remove )
        end

      end

      describe "created three weeks ago, friday" do

        let( :weeksagofriday ) do
          allow(File).to receive( :directory? ).with( SOURCE_PATH ) { false }
          allow(File).to receive( :mtime ).with( SOURCE_PATH ) { weeks_ago( 3, 'Fri' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Friday files', 'Older than Two Weeks'" do
          expect(weeksagofriday.description).to include( "'Friday' files" )
          expect(weeksagofriday.description).to include( 'Older than Two Weeks' )
        end

        it "should invoke action :remove" do
          expect(weeksagofriday.action).to eq( :retain )
        end

      end

      describe "created three months ago, friday" do

        let( :oldfriday ) do
          allow(File).to receive( :directory? ).with( SOURCE_PATH ) { false }
          allow(File).to receive( :mtime ).with( SOURCE_PATH ) { weeks_ago( 12, 'Fri' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Older than Two Months'" do
          expect(oldfriday.description).to include( 'Older than Two Months' )
        end

        it "should invoke action :archive" do
          expect(oldfriday.action).to eq( :archive )
        end

      end

      describe "created three months ago, wednesday" do

        let( :oldwednesday ) do
          allow(File).to receive( :directory? ).with( SOURCE_PATH ) { false }
          allow(File).to receive( :mtime ).with( SOURCE_PATH ) { weeks_ago( 12, 'Wed' ) }
          subject.categorize( SOURCE_FILE )
        end

        it "should be described as 'Non-Friday files', 'Older than Two Weeks'" do
          expect(oldwednesday.description).to include( "'Non-Friday' files" )
          expect(oldwednesday.description).to include( "Older than Two Weeks" )
        end

        it "should invoke action :remove" do
          expect(oldwednesday.action).to eq( :remove )
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
      expect(subject.categorize( "." ).description).to eq( "Ignoring" )
    end
    
    it "should ignore files not matching pattern" do
      allow(File).to receive(:file?) { true }
      expect(subject.categorize( 'readme.txt' ).description).to eq( 'Ignoring' )
    end
    
    describe "with a file named with 20101001" do
      before do
        allow(File).to receive(:directory?) { false }
        allow(File).to receive(:file?) { true }
      end
      
      it "should categorize as 2010" do
        expect(subject.categorize( 'mysql-prod-20101001.sql.gz' ).description).to eq( '2010' )
      end
    end

    describe "with a file named with 20110215" do
      before do
        allow(File).to receive(:directory?) { false }
        allow(File).to receive(:file?) { true }
      end
      
      it "should categorize as 2011" do
        expect(subject.categorize( 'subversion-20110215.tar.gz' ).description).to eq( '2011' )
      end
    end
  end

end

def weeks_ago( weeks, weekday )
  sub_weeks = Time.now - ( DAY * 7 * weeks )
  weekday_adjustment = Time.now.wday - Date::ABBR_DAYNAMES.index( weekday )
  sub_weeks - ( weekday_adjustment * DAY )
end
