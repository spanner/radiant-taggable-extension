module TaggableSiteController      # for inclusion into SiteController
  
  def self.included(base)
    
    base.class_eval {

      def find_page_with_tags(url)
        url = clean_url(url)
        page = find_page_without_tags(url)
        return page unless page.is_a?(TagPage)
        page.add_request_tags(Tag.in_this_list(params[:tag])) if params[:tag]      
        raise TagPage::RedirectRequired, page.tagged_url unless page.tagged_url == url     # to handle removal of tags and ensure consistent addressing. should also allow cache hit.
        page
      end
      alias_method_chain :find_page, :tags

      def show_page_with_tags
        show_page_without_tags
      rescue TagPage::RedirectRequired => e
        logger.warn "!!  redirected to #{e.message}"
        redirect_to e.message
      end
      alias_method_chain :show_page, :tags
      
    protected
      def clean_url(url)
        "/#{ url.strip }/".gsub(%r{//+}, '/')
      end
      
    }
  end
end