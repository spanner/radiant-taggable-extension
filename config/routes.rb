ActionController::Routing::Routes.draw do |map|
  map.namespace :admin do |admin|
    #admin.resources :tags, :member => {:remove => :get }, :collection => {:cloud => :get}
    admin.resources :tags, :except => [:new], :member => {:remove => :get }, :collection => {:search => :get}
    admin.resources :taggings, :only => [:destroy]
  end
end
