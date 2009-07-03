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

# module CountFix
#   def self.included(base)
#     base.class_eval do
#       extend ClassMethods
#       class << self; alias_method_chain :construct_count_options_from_args, :fix; end
#     end
#   end
#   
#   module ClassMethods
#     protected
#       def construct_count_options_from_args_with_fix(*args)
#         column_name, options = construct_count_options_from_args_without_fix(*args)
#         column_name = '*' if column_name =~ /\.\*$/
#         [column_name, options]
#       end
#   end
# end
# ActiveRecord::Base.send :include, CountFix
