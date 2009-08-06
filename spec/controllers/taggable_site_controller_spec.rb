require File.dirname(__FILE__) + '/../spec_helper'
Radiant::Config['reader.layout'] = 'Main'

describe SiteController do
  dataset :tag_pages

  before do
    controller.stub!(:request).and_return(request)
  end

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
    


end
