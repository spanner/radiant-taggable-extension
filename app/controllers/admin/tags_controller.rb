class Admin::TagsController < Admin::ResourceController
  
  def index 
    @tags = Tag.with_count
    response_for :plural
  end
  
  def show
    @tag = load_model
  end
  
  def cloud
    @tags = Tag.sized(Tag.with_count)
    response_for :plural
  end
    
end
