class Admin::TagsController < Admin::ResourceController
  
  def index 
    @tags = Tag.with_count
    response_for :plural
  end
  
  def cloud
    @tags = Tag.banded(Tag.with_count)
    response_for :plural
  end
    
end
