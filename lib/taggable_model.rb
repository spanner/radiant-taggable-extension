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
      
      # note that you have to avoid anything that will call count on this scope
      # and that includes for example calling assets.empty? before there has been a find:
      # empty? is sugared so that it counts rather than finding and then lengthing
      named_scope :from_tags, lambda { |tags| 
        {
          :joins => "INNER JOIN taggings on taggings.tagged_id = #{self.table_name}.id AND taggings.tagged_type = '#{self.to_s}'", 
          :conditions => ["taggings.tag_id in(#{tags.map{ '?' }.join(',')})"] + tags.map(&:id),
          :group => "taggings.tagged_id",
          :order => "count(taggings.id) DESC"
        }
      }

      named_scope :from_all_tags, lambda { |tags| 
        {
          :joins => "INNER JOIN taggings on taggings.tagged_id = #{self.table_name}.id AND taggings.tagged_type = '#{self.to_s}'", 
          :conditions => ["taggings.tag_id in(#{tags.map{ '?' }.join(',')})"] + tags.map(&:id),
          :group => "#{self.table_name}.id",
          :having => "count(taggings.id) >= #{tags.length}"
        }
      } do
        # count is badly sugared here: it omits the group and having clauses.
        # length performs the query and looks at the array: less neat, but more right
        # this gives us back any? and empty? as well.
        def count
          length
        end
      end
      
      # this sets up eg Taggings.of_model
      # and then uses that to define instance methods in Tag:
      # tag.models
      # tag.models_count
      Tag.define_class_retrieval_methods(self.to_s)
      
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
      Tag.attached_to(these).most_popular(limit)   # here popularity is use-count *within the group*
    end
  end
  
  module TaggableInstanceMethods

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
    
    def tags_for_cloud(limit=50, bands=6)

      # here do we want to display local tags with global prominence?

    end
    
  end

end

