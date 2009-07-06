require File.dirname(__FILE__) + '/../spec_helper'

describe TagPage do
  dataset :tag_pages
  
  it "should be a Page" do
    page = TagPage.new
    page.is_a?(Page).should be_true
  end
  
  describe "on request" do
    before do
      @page = Page.find_by_url('/tags/colourless')
    end
  
    it "should interrupt find_by_url" do
      @page.should == pages(:tags)
      @page.is_a?(TagPage).should be_true
    end

    it "should set tag context" do
      @page.requested_tag.should == tags(:colourless)
    end
  end
  
end
