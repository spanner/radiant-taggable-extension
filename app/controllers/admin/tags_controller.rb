class Admin::TagsController < Admin::ResourceController
  helper :taggable
  
  def index 
    @tags = Tag.with_count.sort
    response_for :plural
  end
  
  def show
    @tag = load_model
  end
  
  def cloud
    @tags = Tag.sized(Tag.with_count).sort
    response_for :plural
  end
    
end
