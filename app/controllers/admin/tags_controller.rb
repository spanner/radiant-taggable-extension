class Admin::TagsController < Admin::ResourceController
  helper :taggable
  
  def index
    tags = params[:query] ? Tag.suggested_by(params[:query]) : Tag.with_count
    @tags = tags.sort
    respond_to do |wants|
      wants.xml { render :xml => @tags }
      wants.json { render :json => @tags.map(&:title)  }
      wants.any
    end
  end

  def search
    tags = params[:page][:keywords] ? Tag.suggested_by(params[:page][:keywords]) : Tag.with_count
    @tags = tags.sort
    # TODO: Filter out already inserted keywords?
    render "_autocomplete", :layout => false
  end

  def show
    @tag = load_model
  end
  
  def cloud
    @tags = Tag.sized(Tag.with_count).sort
    response_for :plural
  end

  def remove
    @tag = load_model
  end
    
end
