module TaggableAdminPageController      # for inclusion into Admin::PagesController

  # here we have a few more special cases for page tags.
  # mostly just interface niceties
  
  def self.included(base)
    
    base.class_eval {

      def initialize_meta_rows_and_buttons_with_tags
        initialize_meta_rows_and_buttons_without_tags
        @meta.delete(@meta.find{|m| m[:field] == 'keywords'})
      end
      alias_method_chain :initialize_meta_rows_and_buttons, :tags

    }
  end
end