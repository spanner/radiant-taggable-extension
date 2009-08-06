require 'digest/sha1'

class TagPagesDataset < Dataset::Base
  uses :tags
  
  def load
    create_page "tags", :slug => "tags", :class_name => 'TagPage', :body => 'Tag Page'
  end
 
end