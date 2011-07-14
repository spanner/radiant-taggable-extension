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
  
  it "should stringify as title" do
    "#{tags(:colourless)}".should == 'colourless'
  end

  it "should <=> by title" do
    tags = Tag.from_list('ideas,colourless,lifebelt')
    tags.sort.first.should == tags(:colourless)
  end

  it "should sort tags naturally" do
    tags = Tag.from_list('item2, item11, item13, item20, item1, item0')
    tags.sort.join(' ').should == %{item0 item1 item2 item11 item13 item20}
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
  
  describe "coinciding" do
    
  end
end
