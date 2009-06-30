class Tag < ActiveRecord::Base

  attr_accessor :use_count, :cloud_band
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_many :taggings, :dependent => :destroy
  is_site_scoped if defined? ActiveRecord::SiteNotFound

  named_scope :with_count, {
    :select => "tags.*, count(taggings.id) as use_count", 
    :joins => "INNER JOIN taggings on taggings.tag_id = tags.id", 
    :group => "taggings.tag_id", 
    :order => 'title ASC'
  }
  
  named_scope :most_popular, lambda { |count|
    {
      :select => "tags.*, count(taggings.id) as use_count", 
      :joins => "INNER JOIN taggings on taggings.tag_id = tags.id", 
      :group => "taggings.tag_id",
      :limit => count,
      :order => 'use_count DESC'
    }
  }
  
  named_scope :attached_to, lambda { |these|
    klass = these.first.is_a?(Page) ? Page : these.first.class
    {
      :joins => "INNER JOIN taggings on taggings.tag_id = tags.id", 
      :conditions => ["taggings.tagged_type = '#{klass}' and taggings.tagged_id IN (#{these.map{'?'}.join(',')})", *these.map{|p| p.id}],
    }
  }
  
  def sited?
    !reflect_on_association(:site).nil?
  end

  def self.from_list(list='')
    return [] if list.blank?
    list.split(/[,;]\s*/).uniq.map { |t| self.for(t) }
  end
  
  def self.for(title)
    sited? ? self.find_or_create_by_title_and_site_id(title, Page.current_site.id) : self.find_or_create_by_title(title)
  end
  
  def self.banded(tags, bands=6)
    if tags && tags.any?
      count = tags.map{|t| t.use_count.to_i}
      max_use = count.max
      min_use = count.min
      divisor = ((max_use - min_use) / bands) + 1
      tags.each do |tag|
        tag.cloud_band = (tag.use_count.to_i - min_use) / divisor
      end
      tags
    end
  end
    
  def self.addTaggableMethodsTo(classname)
    Tagging.send :named_scope, "of_#{classname.downcase.pluralize}".intern, :conditions => { :tagged_type => classname.to_s }
    define_method("#{classname.downcase}_taggings") { self.taggings.send "of_#{classname.to_s}".to_i }
    define_method("#{classname.downcase.pluralize}") { self.send("#{classname.to_s.downcase}_taggings".to_i).map{|l| l.tagged} }
    define_method("#{classname.downcase.pluralize}_count") { self.send("#{classname.to_s.downcase}_taggings".to_i).length }
  end
      
end

