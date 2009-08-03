module TaggableSiteController      # for inclusion into SiteController
  
  def self.included(base)
    
    base.class_eval {

      def find_page_with_tags(url)
        page = find_page_without_tags(url)
        return page unless page.is_a?(TagPage)
        page.add_request_tags(Tag.in_this_list(params[:tag]))
        page
      end
      alias_method_chain :find_page, :tags

    }
  end
end