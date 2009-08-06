require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  dataset :tags
  
  it "should reuse an existing tag if possible" do
    tag = Tag.for('colourless')
    tag.should == tags(:colourless)
  end
  
  it "should create a tag where none exists" do
    tag = Tag.for('calumny')
    tag.should be_valid
    tag.new_record?.should be_false
  end

  it "should find_or_create tags from a list" do
    tags = Tag.from_list('colourless,ideas,lifebelt')
    tags[0].should == tags(:colourless)
    tags[1].should == tags(:ideas)
    tags[2].created_at.should be_close((Time.now).utc, 10.seconds)
  end
  
  describe "instantiated" do
    before do
      @tag = tags(:sleep)
    end
    
    it "should have retrieval methods for taggable models" do
      @tag.respond_to?(:page_taggings).should be_true
      @tag.respond_to?(:pages).should be_true
    end
    
    it "should return its list of pages" do
      @tag.pages.should == [pages(:first)]
    end
    
  end
end
