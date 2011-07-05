require File.dirname(__FILE__) + '/../spec_helper'

describe LibraryPage do
  dataset :tags
  
  it "should be a Page" do
    page = LibraryPage.new
    page.is_a?(Page).should be_true
  end
  
  describe "on request" do
    describe "with one tag" do
      before do
        @page = Page.find_by_url('/library/colourless')
      end
  
      it "should interrupt find_by_url" do
        @page.should == pages(:library)
        @page.is_a?(LibraryPage).should be_true
      end

      it "should set tag context correctly" do
        @page.requested_tags.should == [tags(:colourless)]
      end
    end
    
    describe "with several tags" do
      before do
        @page = Page.find_by_url('/library/colourless/green/ideas')
      end
      it "should set tag context correctly" do
        @page.requested_tags.should == [tags(:colourless), tags(:green), tags(:ideas)]
      end
    end
    
    describe "with several tags and one tag negation" do
      before do
        @page = Page.find_by_url('/library/colourless/green/ideas/-green')
      end
      it "should set tag context correctly" do
        @page.requested_tags.should == [tags(:colourless), tags(:ideas)]
      end
    end
    
  end
  
end
