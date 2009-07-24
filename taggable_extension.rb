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
    Page.send :include, TaggableTags                                    # radius tags for lists and clouds
    Admin::PagesController.send :include, TaggablePageController        # tweak the admin interface to make tags more prominent
    UserActionObserver.instance.send :add_observer!, Tag                # tags take part in the usual create and update records
    TagPage                                                             # page type that reads tags from url

    admin.tabs.add "Tags", "/admin/tags", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    admin.tabs.remove "Tags"
  end
  
end
