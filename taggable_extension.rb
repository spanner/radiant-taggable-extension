class TaggableExtension < Radiant::Extension
  version "1.1"
  description "General purpose tagging and taxonomy extension: more versatile but less immediately useful than the tags extension"
  url "http://spanner.org/radiant/taggable"
  
  define_routes do |map|
    map.namespace :admin do |admin|
      admin.resources :tags, :collection => {:cloud => :get}
    end
  end
  
  def activate
    ActiveRecord::Base.send :include, TaggableModel                     # provide is_taggable for everything but don't call it for anything
    Page.send :is_taggable                                              # make pages taggable 
    Page.send :include, TaggablePage                                    # then take over the keywords column and add some tweaks specific to the page tree
    Page.send :include, TaggableTags                                    # create radius tags for tags, lists and clouds
    Admin::PagesController.send :include, TaggableAdminPageController   # tweak the admin interface to make page tags more prominent
    UserActionObserver.instance.send :add_observer!, Tag                # tags get creator-stamped
    TagPage                                                             # page type that reads tags from url
    SiteController.send :include, TaggableSiteController                # and from tag[] parameters

    unless defined? admin.tag
      Radiant::AdminUI.send :include, TaggableAdminUI
      admin.tag = Radiant::AdminUI.load_default_tag_regions
      if defined? Site
        admin.tag.index.add :top, "admin/shared/site_jumper"
      end
    end

    admin.tabs.add "Tags", "/admin/tags", :after => "Layouts", :visibility => [:all]
    if admin.tabs['Tags'].respond_to?(:add_link)
      admin.tabs['Tags'].add_link('tag list', '/admin/tags')
      admin.tabs['Tags'].add_link('tag cloud', '/admin/tags/cloud')
      admin.tabs['Tags'].add_link('new tag', '/admin/tags/new')
    end
  end
  
  def deactivate
    admin.tabs.remove "Tags"
  end
  
end
