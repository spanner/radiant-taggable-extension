module Taggable
  module Page      # for inclusion into Page

    # here we have a few special cases for page tags.
    # because of the page tree
  
    def self.included(base)
      base.class_eval {
        has_tags
        has_one :pointer, :class_name => 'Tag'
        named_scope :children_of, lambda { |these|
          { :conditions => ["parent_id IN (#{these.map{'?'}.join(',')})", *these.map{|t| t.id}] }
        }
        extend Taggable::Page::ClassMethods
        include Taggable::Page::InstanceMethods
      }
    end

    module ClassMethods
    end

    module InstanceMethods

      def has_pointer?
        !pointer.nil?
      end

      # note varying logic here: tag clouds are used differently when describing a group.
      # if only one object is relevant, all of its tags will be equally (locally) important. 
      # Presumably that cloud should show global tag importance.
      # If several objects are relevant, either from a list or a tree of descendants, we  
      # probably want to show local tag importance, ie prominence within that list.
    
      def tags_for_cloud(limit=50, bands=6)
        tags = Tag.attached_to(self.with_children).visible.most_popular(limit)
        Tag.sized(tags, bands)
      end
    
      # the family-tree builder works with generations instead of individuals to cut down the number of retrieval steps
    
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

    end
  end
end