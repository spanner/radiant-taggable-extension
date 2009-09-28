class Tagging < ActiveRecord::Base

  belongs_to :tag
  belongs_to :tagged, :polymorphic => true

  named_scope :with, lambda { |tag|
    {
      :conditions => ["taggings.tag_id = ?", tag.id]
    }
  }
  named_scope :with_any_of_these, lambda { |tags| 
    {
      :select => "taggings.*", 
      :conditions => ["taggings.tag_id IN (#{tags.map{'?'}.join(',')})", *tags.map{|t| t.is_a?(Tag) ? t.id : t}],
      :group => "taggings.tagged_type, taggings.tagged_id"
    }
  }
  
  # this scope underpins a lot of the faceting:
  # it returns a list of taggings of objects to whom all the supplied tags have been applied
  # and is always used with map(&:tagged) to get a list of objects
  
  named_scope :with_all_of_these, lambda { |tags| 
    {
      :select => "taggings.*", 
      :conditions => ["taggings.tag_id IN (#{tags.map{'?'}.join(',')})", *tags.map{|t| t.is_a?(Tag) ? t.id : t}],
      :group => "taggings.tagged_type, taggings.tagged_id",
      :having => "COUNT(taggings.tag_id) >= #{tags.length}"
    }
  }
  
  # good housekeeping idea from tags extension.
  # if all the taggings for a particular tag are deleted, we want to delete the tag too
  
  def before_destroy
    tag.destroy_without_callbacks if Tagging.with(tag).count < 1
  end    
  
end
