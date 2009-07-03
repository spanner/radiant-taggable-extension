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
      named_scope :from_tags, lambda { |tags| 
        {
          :select => "#{self.table_name}.*, count(taggings.id) as match_count", 
          :joins => "INNER JOIN taggings on taggings.tagged_id = #{self.table_name}.id AND taggings.tagged_type = '#{self.to_s}'", 
          :conditions => ["taggings.tag_id in(#{tags.map{ '?' }.join(',')})"] + tags.map{|l| l.id},
          :group => "taggings.tagged_id", 
          :order => 'match_count DESC'
        }
      }
      
      named_scope :children_of, lambda { |these|
        {
          :conditions => ["parent_id IN (#{these.map{'?'}.join(',')})", *these.map{|t| t.id}]
        }
      }
      
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
    
    def tags_for_cloud_from(these, limit=50)
      Tag.attached_to(these).most_popular(limit)   # popularity is use-count within the group
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
    
    # note varying logic here: tag clouds are used differently when describing a group.
    # if only one object is relevant, all of its tags will be equally (locally) important. 
    # Presumably that cloud should show global tag importance.
    # If several objects are relevant, either from a list or a tree of descendants, we  
    # probably want to show local tag importance, ie prominence within that list.
    
    def tags_for_cloud(limit=50, bands=6)
      tags = Tag.attached_to(self.with_children).most_popular(limit)
      Tag.banded(tags, bands)
    end
    
    def with_children
      this_generation = [self]
      return this_generation unless self.respond_to?(:children) && self.children.any?
      family = [self]
      while this_generation.any? && next_generation = self.class.children_of(this_generation)
        family.push(*next_generation)
        this_generation = next_generation
      end
      family
    end
    
    def related
      self.attached_tags.empty? ? [] : self.class.from_tags(self.attached_tags) - [self]
    end
    
    def closely_related
      self.attached_tags.empty? ? [] : self.class.from_tags(self.attached_tags).select { |p| p != self && p.match_count.to_i >= self.attached_tags.count }
    end
  end

end

