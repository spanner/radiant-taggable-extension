class Tagging < ActiveRecord::Base

  belongs_to :tag
  belongs_to :tagged, :polymorphic => true
  named_scope :of_pages, :conditions => { :tagged_type => 'Page' }
  named_scope :with_tag, lambda { |tag| 
    {:conditions => ["taggings.tag_id = ?", tag.id]}
  }
  
  # good idea from tags extension. housekeeping:
  # if all the taggings for a particular tag are deleted, we want to delete the tag too
  
  def before_destroy
    tag.destroy_without_callbacks if Tagging.with_tag(tag).count < 1
  end    
  
end
