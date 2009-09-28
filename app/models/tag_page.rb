class TagPage < Page

  class RedirectRequired < StandardError
    def initialize(message = nil); super end
  end

  description %{ Takes tag names in child position or as paramaters so that tagged items can be listed. }
  
  attr_accessor :requested_tags, :strict_match
  
  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    my_url = self.url
    return false unless url =~ /^#{Regexp.quote(my_url)}(.*)/
    tags = $1.split('/')
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
  
  # must return a scoped finder that can be chained
  
  def assets
    if requested_tags.any?
      Asset.from_all_tags(requested_tags)
    else
      Asset.all
    end
  end
  
  # this isn't very pleasing but it's the best way to let the controller know 
  # of our real address once tags have been added and removed.
  
  def tagged_url(tags = requested_tags)
    clean_url( url + '/' + tags.uniq.map(&:clean_title).to_param )
  end
  
end
