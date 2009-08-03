class TagPage < Page

  description %{ Takes tag names in child position or as paramaters so that tagged items can be listed. }
  
  attr_accessor :requested_tags, :strict_match
  
  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    add_request_tags(url.gsub(/^#{ self.url }\/?/, '').split('/'))
    self
  end
  
  def add_request_tags(tags=[])
    if tags.any?
      tags.collect! { |tag| tag.is_a?(Tag) ? tag : Tag.find_by_title(Rack::Utils::unescape(tag)) }
      self.requested_tags = (self.requested_tags + tags).uniq
    end
  end
  
  def requested_tags
    @requested_tags ||= []
  end
  
end
