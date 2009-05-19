class Tag < ActiveRecord::Base

  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_many :taggings, :dependent => :destroy  
  named_scope :with_count, {
    :select => "tags.*, count(taggings.id) as use_count", 
    :joins => "INNER JOIN taggings on taggings.tag_id = tags.id", 
    :group => "taggings.tagged_id", 
    :order => 'title ASC'
  }
  
  def self.from_list(list='')
    return [] if list.blank?
    list.split(/[,;]\s*/).uniq.map { |t| self.find_or_create_by_title(t) }
  end
  
  def self.for(title)
    self.find_or_create_by_title(title)
  end

  def page_taggings
    self.taggings.of_pages
  end

  def pages
    self.page_taggings.map{|l| l.labelled}
  end
    
  def pages_count
    self.page_taggings.length
  end
    
end

