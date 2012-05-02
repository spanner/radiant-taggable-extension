module Taggable
  class RedirectRequired < StandardError
    def initialize(message = nil); super end
  end
  
  module FacetedPage
    
    # This module can be mixed into any Page subclass to give it mystical web 2.0 faceting powers.
    # Any nonexistent child path is assumed to be a tag set, and methods are provided for reading
    # that set, and adding and removing tags.
    #
    def self.included(base)
      base.extend ClassMethods
      base.class_eval {
        include InstanceMethods
        alias_method_chain :path, :tags
      }
    end
    
    module ClassMethods
    end

    module InstanceMethods

      # Faceted pages map nicely onto urls and are cacheable. 
      # There can be redundancy if tags are specified in varying order,
      # but the site controller tries to normalize everything.
      #
      def cache?
        true
      end

      # We override the normal Page#find_by_path mechanism and treat nonexistent child paths
      # are understood as tag sets. Note that the extended site_controller will add to this set
      # any tags that have been supplied in query string parameters. This may trigger a redirect
      # to bring the request path into line with the consolidated tag set.
      #
      def find_by_path(path, live = true, clean = false)
        path = clean_path(path) if clean
        return false unless path =~ /^#{Regexp.quote(self.path)}(.*)/
        tags = $1.split('/')
        if slug_child = children.find_by_slug(tags[0])
          found = slug_child.find_by_url(path, live, clean)
          return found if found
        end
        remove_tags, add_tags = tags.partition{|t| t.first == '-'}
        add_request_tags(add_tags)
        remove_request_tags(remove_tags)
        self
      end
      alias_method :find_by_url, :find_by_path

      # The set of tags attached to the page request.
      #
      def requested_tags
        @requested_tags ||= []
      end

      # The normal `path` method is extended to append the (sorted and deduped) tags attached to the page request
      #
      def path_with_tags(tags = requested_tags)
        clean_path( path_without_tags + '/' + tags.uniq.compact.sort.map(&:clean_title).to_param )
      end

    private
  
      # @requested_tags is the set of Tag objects attached to the page request.
      #
      def requested_tags=(tags)
        @requested_tags = tags
      end

      # We hold in memory a list of the tags that were appended to the path when this page was selected.
      # This method adds tags to that list. It is normally called only once, to populate the list.
      #
      def add_request_tags(tags=[])
        if tags.any?
          tags.collect! { |tag| Tag.find_by_title(Rack::Utils::unescape(tag)) }
          #tags.collect! { |tag| Tag.find_by_title(tag) }
          self.requested_tags = (self.requested_tags + tags.select{|t| !t.nil?}).uniq
        end
      end

      # This method removes tags from the appended list. Normally only used to handle defaceting links
      # (in the form /path/to/page/tag1/tag2/tag3/-tag2).
      #
      def remove_request_tags(tags=[])
        if tags.any?
          tags.collect! { |tag|
            tag.slice!(0) if tag.first == '-' 
            Tag.find_by_title(Rack::Utils::unescape(tag)) 
          }
          self.requested_tags = (self.requested_tags - tags.compact).uniq
        end
      end
    end

  end
end