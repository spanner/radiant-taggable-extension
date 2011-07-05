module Taggable
  module Asset
  
    def self.included(base)
      base.class_eval {
        has_tags
        named_scope :furniture, {:conditions => 'assets.furniture = 1'}
        named_scope :not_furniture, {:conditions => 'assets.furniture = 0 or assets.furniture is null'}

        extend Taggable::Asset::ClassMethods
        include Taggable::Asset::InstanceMethods
      }
    end

    module ClassMethods
    end

    module InstanceMethods

      # just keeping compatibility with page tags
      # so as to present the same interface

      def keywords 
        self.attached_tags.map {|t| t.title}.join(', ')
      end
    
      def keywords=(somewords="")
        self.attached_tags = Tag.from_list(somewords)
      end
    
      def keywords_before_type_cast   # called by form_helper
        keywords
      end

    end
  end
end