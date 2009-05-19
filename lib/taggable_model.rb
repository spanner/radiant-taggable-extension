module TaggableModel
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def is_taggable?
      false
    end

    def is_taggable
      return if is_taggable?
      class_eval <<-EO
        extend TaggableModel::TaggableClassMethods
        include TaggableModel::TaggableInstanceMethods
      EO
      
      has_many :taggings, :as => :tagged
      has_many :tags, :through => :taggings
      named_scope :from_tags, lambda { |tags| {
        :select => "#{self.table_name}.*, count(taggings.id) as match_count", 
        :joins => "INNER JOIN taggings on taggings.tagged_id = #{self.table_name}.id AND taggings.tagged_type = '#{self.to_s}'", 
        :conditions => ["taggings.tag_id in(#{tags.map{ '?' }.join(',')})"] + tags.map{|l| l.id},
        :group => "taggings.tagged_id", 
        :order => 'match_count DESC'
      }}
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
      self.tags.map {|t| t.title}.join(', ')
    end
    
    def keywords=(somewords="")
      tags = Tag.from_list(somewords)
      self.tags.each { |tag| self.tags.delete(tag) unless tags.include?(tag) }
      tags.each { |tag| self.tags << tag unless self.tags.include?(tag) }
    end
    
    def keywords_before_type_cast   # ugh! but necessary for form_helper to show the tags in the keyword boxm when editing pages
      keywords
    end

    def add_tag(word=nil)
      self.tags << Tag.for(word) if word && !word.blank?
    end

    def remove_tag(word=nil)
      tag = Tag.find_by_title(word) if word && !word.blank?
      self.tags.delete(tag) if tag
    end
    
    def related
      self.tags.empty? ? [] : self.class.from_tags(self.tags) - [self]
    end
    
    def closely_related
      self.tags.empty? ? [] : self.class.from_tags(self.tags).select { |p| p != self && p.match_count.to_i >= self.tags.count }
    end
    
  end

end

