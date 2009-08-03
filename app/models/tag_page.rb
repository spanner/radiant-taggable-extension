class TagPage < Page

  description %{ Takes tag names in child position so that tagged items can be listed. }
  
  attr_accessor :requested_tags
  
  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    add_request_tags(url.gsub(/^#{ self.url }\/?/, '').split('/'))
    self
  end
  
  def add_request_tags(tags=[])
    logger.warn("++ add_request_tags: #{tags.inspect}")
    if tags.any?
      self.requested_tags = [] unless self.requested_tags
      tags.collect! { |tag| tag.is_a?(Tag) ? tag : Tag.find_by_title(Rack::Utils::unescape(tag)) }
      self.requested_tags = (self.requested_tags + tags).uniq
    end
  end
end
