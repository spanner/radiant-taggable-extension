# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class TaggableExtension < Radiant::Extension
  version "1.0"
  description "General purpose tagging and taxonomy-management extension: more versatile but less focused than the tags extension"
  url "http://spanner.org/radiant/taggable"
  
  define_routes do |map|
    map.namespace :admin, :member => { :remove => :get } do |admin|
      admin.resources :tags
    end
  end
  
  def activate
    ActiveRecord::Base.send :include, MultiSite::TaggableModel
    Page.send :is_taggable
    Page.send :include, TaggableTags
    UserActionObserver.instance.send :add_observer!, Tag 
    admin.tabs.add "Tags", "/admin/tags", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Taggable"
  end
  
end
