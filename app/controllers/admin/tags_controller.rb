class Admin::TagsController < Admin::ResourceController
  helper :taggable
  
  def index
    tags = params[:query] ? Tag.suggested_by(params[:query]) : Tag.with_count
    @tags = tags.sort
    respond_to do |wants|
      wants.xml { render :xml => @tags }
      wants.json { render :json => { 'query' => params[:query], 'suggestions' => @tags.map(&:title) } }
      wants.any
    end
  end
  
  def show
    @tag = load_model
  end
  
  def cloud
    @tags = Tag.sized(Tag.with_count).sort
    response_for :plural
  end
    
end
