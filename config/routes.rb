ActionController::Routing::Routes.draw do |map|
  map.namespace :admin do |admin|
    admin.resources :tags, :member => {:remove => :get }, :collection => {:cloud => :get}
    admin.resources :taggings, :only => [:destroy]
  end
end
