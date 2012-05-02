require_dependency 'application_controller'
require "radiant-taggable-extension"

class TaggableExtension < Radiant::Extension
  version RadiantTaggableExtension::VERSION
  description RadiantTaggableExtension::DESCRIPTION
  url RadiantTaggableExtension::URL
  
  def activate
    require 'natcmp'                                                      # a natural sort algorithm. possibly not that efficient.
    ActiveRecord::Base.send :include, Taggable::Model                     # provide has_tags for everything but don't call it for anything
    Page.send :include, Taggable::Page                                    # pages are taggable (and the keywords column is overridden)
    Asset.send :include, Taggable::Asset                                  # assets are taggable (and a fake keywords column is provided)
    Page.send :include, Radius::TaggableTags                              # adds the basic radius tags for showing page tags and tag pages
    Page.send :include, Radius::AssetTags                                 # adds some asset:* tags
    Page.send :include, Radius::LibraryTags
    SiteController.send :include, Taggable::SiteController                # some path and parameter handling in support of library pages
    Admin::PagesController.send :include, Taggable::AdminPagesController  # tweaks the admin interface to make page tags more prominent
    UserActionObserver.instance.send :add_observer!, Tag                  # tags get creator-stamped
    Radiant::AdminUI.send :include, Taggable::AdminUI unless defined? admin.tag
    admin.tag ||= Radiant::AdminUI.load_taggable_regions
    admin.asset.edit.add :extended_metadata, 'tags'
		admin.asset.edit.add :extended_metadata, 'furniture'
    admin.page.edit.add :extended_metadata, 'tags'
    admin.configuration.show.add :config, 'admin/configuration/taggable_show' #, :after => 'defaults'
    admin.configuration.edit.add :form,   'admin/configuration/taggable_edit' #, :after => 'edit_defaults'

    tab("Content") do
      add_item("Tags", "/admin/tags")
    end
  end
end
