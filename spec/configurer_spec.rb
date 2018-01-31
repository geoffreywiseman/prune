require 'prune'
require 'spec_helper'
require 'rspec'

describe Prune::Configurer do

  PRUNE_PATH = '/example/prune/folder'
  CONFIG_FILE = "#{PRUNE_PATH}/.prune"
  subject { Prune::Configurer.new(PRUNE_PATH) }

  before do
    ENV.delete( 'EDITOR' )
    ENV.delete( 'VISUAL' )
  end
  
  context "with no config file present" do
    it "should copy core retention policy if no config file" do
      surpress_messages
      expect(FileUtils).to receive(:cp).with( match(/default_retention.rb/), CONFIG_FILE )
      subject.configure
    end
  end

  context "with a directory in place of the config file" do
    before do
      stub_messages 
      allow(File).to receive( :directory? ) { true }
    end
    it "should warn that it can't create file" do
      subject.configure
      expect(@messages).to include_match( /cannot create or edit configuration/ )
    end
  end

  context "with config file that canot be written" do
    before do
      allow(File).to receive( :directory? ).with( CONFIG_FILE ) { false }
      allow(File).to receive( :file? ).with( CONFIG_FILE ) { true }
      allow(File).to receive( :writable? ).with( CONFIG_FILE ) { false }
      stub_messages 
    end
    it "should warn that cannot edit config" do
      subject.configure
      expect(@messages).to include_match( /cannot edit configuration/ )
    end
  end
  
  context "with a writeable config file" do
    
    before do
      allow(File).to receive( :directory? ).with( CONFIG_FILE ) { false }
      allow(File).to receive( :file? ).with( CONFIG_FILE ) { true }
      allow(File).to receive( :writable? ).with( CONFIG_FILE ) { true }
    end
    
    it "should warn if no editor defined" do
      stub_messages 
      subject.configure
      expect(@messages).to include_match( /No editor defined/ )
    end
  
    context "with EDITOR environment variable defined" do
      it "should invoke editor" do
        surpress_messages
        ENV['EDITOR']='ed'
        expect(subject).to receive( :system ).with( "ed #{CONFIG_FILE}" ).and_return( true )
        subject.configure
      end
    end
    
    context "with VISUAL and EDITOR environment variables defined" do
      it "should invoke visual editor" do
        surpress_messages
        ENV['VISUAL']='gedit'
        ENV['EDITOR']='ed'
        expect(subject).to receive( :system ).with( "gedit #{CONFIG_FILE}" ).and_return( true )
        subject.configure
      end
    end
    
    context "with VISUAL environment variable defined" do
      it "should invoke visual editor if defined in VISUAL" do
        surpress_messages
        ENV['VISUAL']='gedit'
        expect(subject).to receive( :system ).with( "gedit #{CONFIG_FILE}" ).and_return( true )
        subject.configure
      end
    end
  end

end
