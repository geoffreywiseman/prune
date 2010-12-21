require 'prune/archiver'
#require 'fakefs'

describe Prune::Archiver do
  
  describe "with a /mysql source" do
    subject { Prune::Archiver.new( nil, '/mysql', true ) }
    
    it "should have /mysql-archives destination" do
      subject.destination.should eq( '/mysql-archives' )
    end
    
    pending "Should create destination folder if it doesn't exist."
    pending "Should archive files to the destination folder."
    
    describe "and a /mysql/archives destination" do
      subject { Prune::Archiver.new( '/mysql/archives', '/mysql', true ) }
      
      it "should use the explicit destination" do
        subject.destination.should eq( '/mysql/archives' )
      end
    end
  end
  
end