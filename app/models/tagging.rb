class Tagging < ActiveRecord::Base

  belongs_to :tag
  belongs_to :tagged, :polymorphic => true

  named_scope :with_tag, lambda { |tag| 
    {:conditions => ["taggings.tag_id = ?", tag.id]}
  }
  
  # good housekeeping idea from tags extension.
  # if all the taggings for a particular tag are deleted, we want to delete the tag too
  
  def before_destroy
    tag.destroy_without_callbacks if Tagging.with_tag(tag).count < 1
  end    
  
end
