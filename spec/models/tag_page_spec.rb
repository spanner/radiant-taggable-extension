require File.dirname(__FILE__) + '/../spec_helper'

describe TagPage do
  dataset :tag_pages
  
  it "should be a Page" do
    page = TagPage.new
    page.is_a?(Page).should be_true
  end
  
  describe "on request" do
    describe "with one tag" do
      before do
        @page = Page.find_by_url('/tags/colourless')
      end
  
      it "should interrupt find_by_url" do
        @page.should == pages(:tags)
        @page.is_a?(TagPage).should be_true
      end

      it "should set tag context correctly" do
        @page.requested_tags.should == [tags(:colourless)]
      end
    end
    
    describe "with several tags" do
      before do
        @page = Page.find_by_url('/tags/colourless/green/ideas')
      end
      it "should set tag context correctly" do
        @page.requested_tags.should == [tags(:colourless), tags(:green), tags(:ideas)]
      end
    end
    
    describe "with several tags and one tag negation" do
      before do
        @page = Page.find_by_url('/tags/colourless/green/ideas/-green')
      end
      it "should set tag context correctly" do
        @page.requested_tags.should == [tags(:colourless), tags(:ideas)]
      end
    end
    
  end
  
end
