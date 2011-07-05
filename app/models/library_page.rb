class LibraryPage < Page
  include WillPaginate::ViewHelpers

  class RedirectRequired < StandardError
    def initialize(message = nil); super end
  end

  description %{ Takes tag names in child position or as paramaters so that tagged items can be listed. }
  
  attr_accessor :requested_tags, :strict_match
  
  def cache?
    true
  end
  
  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    my_url = self.url
    return false unless url =~ /^#{Regexp.quote(my_url)}(.*)/
    tags = $1.split('/')
    if slug_child = children.find_by_slug(tags[0])
      found = slug_child.find_by_url(url, live, clean)
      return found if found
    end
    remove_tags, add_tags = tags.partition{|t| t.first == '-'}
    add_request_tags(add_tags)
    remove_request_tags(remove_tags)
    self
  end
  
  def add_request_tags(tags=[])
    if tags.any?
      tags.collect! { |tag| Tag.find_by_title(Rack::Utils::unescape(tag)) }
      self.requested_tags = (self.requested_tags + tags.select{|t| !t.nil?}).uniq
    end
  end
  
  def remove_request_tags(tags=[])
    if tags.any?
      tags.collect! { |tag|
        tag.slice!(0) if tag.first == '-' 
        Tag.find_by_title(Rack::Utils::unescape(tag)) 
      }
      self.requested_tags = (self.requested_tags - tags.select{|t| !t.nil?}).uniq
    end
  end
  
  def requested_tags
    @requested_tags ||= []
  end
  
  # this isn't very pleasing but it's the best way to let the controller know 
  # of our real address once tags have been added and removed.
  
  def url_with_tags(tags = requested_tags)
    clean_url( url_without_tags + '/' + tags.uniq.map(&:clean_title).to_param )
  end
  alias_method_chain :url, :tags
  
end
