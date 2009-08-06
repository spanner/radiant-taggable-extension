require File.dirname(__FILE__) + '/../spec_helper'
Radiant::Config['reader.layout'] = 'Main'

describe SiteController do
  dataset :tag_pages

  describe "on get to a tag page" do
    before do
      get :show_page, :url => '/tags/'
    end
    
    it "should render the tag page" do
      response.should be_success      
      response.body.should == 'Tag Page body.'
    end
    
    describe "with tags in child position" do
      before do
        get :show_page, :url => '/tags/colourless/green/'
      end

      it "should still render the tag page" do
        response.should be_success
        response.body.should == 'Tag Page body.'
      end
    end

    describe "with tags in child position and missing final /" do
      before do
        get :show_page, :url => '/tags/colourless/green'
      end

      it "should still render the tag page" do
        response.should be_success
        response.body.should == 'Tag Page body.'
      end
    end

    describe "with tag negation" do
      before do
        get :show_page, :url => '/tags/colourless/green/-colourless'
      end

      it "should redirect to the reduced address" do
        response.should be_redirect      
        response.should redirect_to('http://test.host/tags/green/')
      end
    end
  end

  describe "caching" do
    it "should add a default Cache-Control header with public and max-age of 5 minutes" do
      get :show_page, :url => '/tags/'
      response.headers['Cache-Control'].should =~ /public/
      response.headers['Cache-Control'].should =~ /max-age=300/
    end

    it "should pass along the etag set by the page" do
      get :show_page, :url => '/tags/'
      response.headers['ETag'].should be
    end

    it "should return a not-modified response when the sent etag matches" do
      response.stub!(:etag).and_return("foobar")
      request.if_none_match = 'foobar'
      get :show_page, :url => '/tags/'
      response.response_code.should == 304
      response.body.should be_blank
    end
  end
    
end
