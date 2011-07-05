require File.dirname(__FILE__) + '/../spec_helper'

describe SiteController do
  dataset :tags

  describe "on get to a library page" do
    before do
      get :show_page, :url => '/library/'
    end
    
    it "should render the tag page" do
      response.should be_success      
      response.body.should == 'Shhhhh. body.'
    end
    
    describe "with tags in child position" do
      before do
        get :show_page, :url => '/library/colourless/green/'
      end

      it "should still render the tag page" do
        response.should be_success
        response.body.should == 'Shhhhh. body.'
      end
    end

    describe "with tags in child position and missing final /" do
      before do
        get :show_page, :url => '/library/colourless/green'
      end

      it "should still render the tag page" do
        response.should be_success
        response.body.should == 'Shhhhh. body.'
      end
    end

    describe "with tag negation" do
      before do
        get :show_page, :url => '/library/colourless/green/-colourless'
      end

      it "should redirect to the reduced address" do
        response.should be_redirect      
        response.should redirect_to('http://test.host/library/green/')
      end
    end
  end

  describe "caching" do
    describe "without tags requested" do
      it "should add a default Cache-Control header with public and max-age of 5 minutes" do
        get :show_page, :url => '/library/'
        response.headers['Cache-Control'].should =~ /public/
        response.headers['Cache-Control'].should =~ /max-age=300/
      end

      it "should pass along the etag set by the page" do
        get :show_page, :url => '/library/'
        response.headers['ETag'].should be
      end

      it "should return a not-modified response when the sent etag matches" do
        response.stub!(:etag).and_return("foobar")
        request.if_none_match = 'foobar'
        get :show_page, :url => '/library/'
        response.response_code.should == 304
        response.body.should be_blank
      end
    end
    
    describe "with tags requested" do
      it "should add a default Cache-Control header with public and max-age of 5 minutes" do
        get :show_page, :url => '/library/green/furiously'
        response.headers['Cache-Control'].should =~ /public/
        response.headers['Cache-Control'].should =~ /max-age=300/
      end

      it "should pass along the etag set by the page" do
        get :show_page, :url => '/library/green/furiously'
        response.headers['ETag'].should be
      end

      it "should return a not-modified response when the sent etag matches" do
        response.stub!(:etag).and_return("foobar")
        request.if_none_match = 'foobar'
        get :show_page, :url => '/library/green/furiously'
        response.response_code.should == 304
        response.body.should be_blank
      end
    end
    
    
  end
    
end
