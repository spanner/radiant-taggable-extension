class Tag < ActiveRecord::Base

  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_many :taggings, :dependent => :destroy
  is_site_scoped if defined? ActiveRecord::SiteNotFound
    
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
  
  def self.addTaggableMethodsTo(classname)
    Tagging.send :named_scope, "of_#{classname.downcase.pluralize}".intern, :conditions => { :tagged_type => classname.to_s }
    define_method("#{classname.downcase}_taggings") { self.taggings.send "of_#{classname.to_s}".to_i }
    define_method("#{classname.downcase.pluralize}") { self.send("#{classname.to_s.downcase}_taggings".to_i).map{|l| l.tagged} }
    define_method("#{classname.downcase.pluralize}_count") { self.send("#{classname.to_s.downcase}_taggings".to_i).length }
  end
    
end

