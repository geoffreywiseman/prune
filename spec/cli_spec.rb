require 'prune/cli'
require 'prune/pruner'
require 'prune/configurer'
require 'spec_helper'
require 'rspec'

describe Prune::CommandLineInterface do
  USAGE_TEXT = /Usage: prune \[options\] folder/
  ARCHIVE_PATH = "/prune/fake/archive-path"

  before(:each) do
    @messages = []
    allow($stdout).to receive( :write ) { |message| @messages << message  }

    @pruner = double( "pruner" )
  end

  describe "with no arguments" do

    it "should print help" do
      ARGV.clear
      Prune::CommandLineInterface::parse_and_run
      expect(@messages).to include_match( USAGE_TEXT )
    end

  end

  describe "with a path argument" do
    PATH = "/prune/fake/path"

    before(:each) do
      ARGV.clear.push( PATH )
      allow(@pruner).to receive(:prune)
    end

    it "should call prune with path" do
      allow(Prune::Pruner).to receive( :new ) { @pruner }
      expect(@pruner).to receive( :prune ).with( PATH )
      Prune::CommandLineInterface::parse_and_run
    end

    it "should create pruner with defaults" do
      allow(Prune::Pruner).to receive( :new ).with( Prune::CommandLineInterface::DEFAULT_OPTIONS ) { @pruner }
      Prune::CommandLineInterface::parse_and_run
    end

    describe "and a -v argument" do
      it "should set verbose option" do
        assert_arg_to_option( "-v", :verbose => true )
      end
    end

    describe "and a --verbose argument" do
      it "should set verbose option" do
        assert_arg_to_option( "--verbose", :verbose => true )
      end
    end

    describe "and a -d argument" do
      it "should set the dry-run option" do
        assert_arg_to_option( "-d", :dry_run => true )
      end
    end

    describe "and a --dry-run argument" do
      it "should set the dry-run option" do
        assert_arg_to_option( "--dry-run", :dry_run => true )
      end
    end

    describe "and a -f argument" do
      it "should set the prompt option to false" do
        assert_arg_to_option "-f", :prompt => false
      end
    end

    describe "and a --force argument" do
      it "should set the prompt option to false" do
        assert_arg_to_option "--force", :prompt => false
      end
    end

    describe "and a --no-prompt argument" do
      it "should set the prompt option to false" do
        assert_arg_to_option "--no-prompt", :prompt => false
      end
    end
    
    describe "and a --config argument" do
      it "should set the configure option to true" do
        configurer = double( "Configurer" )
        expect(Prune::Configurer).to receive( :new ).with( PATH, hash_including( :configure => true ) ).and_return( configurer )
        expect(configurer).to receive( :configure )
        ARGV.push( "--config" )
        Prune::CommandLineInterface::parse_and_run
      end
    end

    describe "and a -a argument" do
      before(:each) do
        ARGV.push "-a"
      end

      describe "with no folder name" do
        it "should print a parsing error" do
          allow($stderr).to receive( :print ) { |message| @messages << message  }
          Prune::CommandLineInterface::parse_and_run
          expect(@messages).to include_match( /missing argument: -a/ )
        end
      end

      describe "with a folder name" do
        it "should set the archive_path option to the folder" do
          assert_arg_to_option ARCHIVE_PATH, :archive_path => ARCHIVE_PATH
        end
      end
    end

    describe "and a --archive-folder argument" do
      before(:each) do
        ARGV.push "--archive-folder"
      end

      describe "with no folder name" do
        it "should print a parsing error" do
          allow($stderr).to receive( :print ) { |message| @messages << message  }
          Prune::CommandLineInterface::parse_and_run
          expect(@messages).to include_match( /missing argument: --archive-folder/ )
        end
      end

      describe "with a folder name" do
        it "should set the archive_path option to the folder" do
          assert_arg_to_option ARCHIVE_PATH, :archive_path => ARCHIVE_PATH
        end
      end
    end

    describe "and a -? argument" do

      before(:each) do
        ARGV.push "-?"
      end

      it "should print help" do
        Prune::CommandLineInterface::parse_and_run
        expect(@messages).to include_match( USAGE_TEXT )
      end

      it "should not invoke prune" do
        expect(@pruner).not_to receive( :prune )
        Prune::CommandLineInterface::parse_and_run
      end

    end

    describe "and a --help argument" do

      before(:each) do
        ARGV.push "--help"
      end

      it "should print help" do
        Prune::CommandLineInterface::parse_and_run
        expect(@messages).to include_match( USAGE_TEXT )
      end

      it "should not invoke prune" do
        expect(@pruner).not_to receive( :prune )
        Prune::CommandLineInterface::parse_and_run
      end

    end

    describe "and an unknown argument" do
      it "should print a parsing error" do
        ARGV.push "--unknown-argument"
        allow($stderr).to receive( :print ) { |message| @messages << message  }
        Prune::CommandLineInterface::parse_and_run
        expect(@messages).to include_match( /invalid option/ )
      end
    end

    describe "and a --version argument" do
      before(:each) do
        ARGV.push "--version"
      end

      it "should print version number" do
          allow($stderr).to receive( :print ) { |message| @messages << message  }
          Prune::CommandLineInterface::parse_and_run
          expect(@messages).to include_match( /Prune #{Prune::VERSION}/ )
      end

      it "should not invoke prune" do
        expect(@pruner).not_to receive( :prune )
        Prune::CommandLineInterface::parse_and_run
      end

    end

    describe "and a --no-archive argument" do
      it "should set the archive option to false" do
        assert_arg_to_option "--no-archive", :archive=>false
      end
    end

    def assert_arg_to_option( arg, *options )
      expect(Prune::Pruner).to receive( :new ).with( hash_including( *options ) ).and_return( @pruner )
      ARGV.push( arg )
      Prune::CommandLineInterface::parse_and_run
    end

  end

end
