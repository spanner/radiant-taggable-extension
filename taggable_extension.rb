class TaggableExtension < Radiant::Extension
  version "1.0"
  description "General purpose tagging and taxonomy extension: more versatile but less immediately useful than the tags extension"
  url "http://spanner.org/radiant/taggable"
  
  define_routes do |map|
    map.namespace :admin do |admin|
      admin.resources :tags, :collection => {:cloud => :get}
    end
  end
  
  def activate
    ActiveRecord::Base.send :include, TaggableModel
    TagPage
    Page.send :is_taggable
    Page.send :include, TaggableTags
    UserActionObserver.instance.send :add_observer!, Tag 
    admin.tabs.add "Tags", "/admin/tags", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    admin.tabs.remove "Tags"
  end
  
end
