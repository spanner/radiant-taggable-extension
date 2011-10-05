module Taggable
  module SiteController

    def self.included(base)
  
      base.class_eval {

        # We override find_page to handle the combination of url tags and parameter tags.
        # If this results in a change to the compound path for this page/tag combination, 
        # we raise a RedirectRequired error.
        #
        def find_page_with_tags(path)
          path = clean_path(path)
          page = find_page_without_tags(path)
          if page.respond_to?(:requested_tags)
            page.add_request_tags(Tag.in_this_list(params[:tag])) if params[:tag]      
            raise Taggable::RedirectRequired, page.path unless page.path == path
          end
          page
        end
        alias_method_chain :find_page, :tags

        # Extends show_page to catch any redirect error raised by find_page, and redirect to the specified path.
        # The effect of this is to standardise all tag-appended requests, which improves cache performance and
        # allows us to defacet by adding -tag parameters.
        #
        # (I can't remember why that was necessary: it may no longer be, so don't rely on it!).
        #
        def show_page_with_tags
          show_page_without_tags
        rescue Taggable::RedirectRequired => e
          redirect_to e.message
        end
        alias_method_chain :show_page, :tags
    
      protected
        def clean_path(path)
          "/#{ path.strip }/".gsub(%r{//+}, '/')
        end
    
      }
    end
  end
end