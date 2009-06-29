module TaggableModel      # for inclusion into ActiveRecord::Base
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def is_taggable?
      false
    end

    def is_taggable
      return if is_taggable?

      has_many :taggings, :as => :tagged
      has_many :attached_tags, :through => :taggings, :source => :tag    # can't be just has_many :tags because that stomps on the radius tags in Page.
      named_scope :from_tags, lambda { |tags| {
        :select => "#{self.table_name}.*, count(taggings.id) as match_count", 
        :joins => "INNER JOIN taggings on taggings.tagged_id = #{self.table_name}.id AND taggings.tagged_type = '#{self.to_s}'", 
        :conditions => ["taggings.tag_id in(#{tags.map{ '?' }.join(',')})"] + tags.map{|l| l.id},
        :group => "taggings.tagged_id", 
        :order => 'match_count DESC'
      }}
      
      Tag.addTaggableMethodsTo(self.to_s)
      
      class_eval {
        extend TaggableModel::TaggableClassMethods
        include TaggableModel::TaggableInstanceMethods
      }
    end
  end

  module TaggableClassMethods
    def tagged_with(somewords='')
      if somewords.blank?
        []
      else
        self.from_tags( Tag.from_list(somewords) )
      end
    end

    def is_taggable?
      true
    end
    
  end
  
  module TaggableInstanceMethods
    
    def keywords 
      self.attached_tags.map {|t| t.title}.join(', ')
    end
    
    def keywords=(somewords="")
      tags = Tag.from_list(somewords)
      self.attached_tags.each { |tag| self.attached_tags.delete(tag) unless tags.include?(tag) }
      tags.each { |tag| self.attached_tags << tag unless self.attached_tags.include?(tag) }
    end
    
    def keywords_before_type_cast   # ugh! but necessary for form_helper
      keywords
    end

    def add_tag(word=nil)
      self.attached_tags << Tag.for(word) if word && !word.blank?
    end

    def remove_tag(word=nil)
      tag = Tag.find_by_title(word) if word && !word.blank?
      self.attached_tags.delete(tag) if tag
    end
    
    def related
      self.attached_tags.empty? ? [] : self.class.from_tags(self.attached_tags) - [self]
    end
    
    def closely_related
      self.attached_tags.empty? ? [] : self.class.from_tags(self.attached_tags).select { |p| p != self && p.match_count.to_i >= self.attached_tags.count }
    end
    
  end

end

