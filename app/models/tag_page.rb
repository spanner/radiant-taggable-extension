class TagPage < Page

  description %{ Takes a tag name in child position so that tagged items can be listed. }

  attr_accessor :tag
  
  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    tagtitles = url.gsub(/^#{ self.url }\/?/, '').split('/')
    @tags = tagtitles.select{|t| !t.blank? }.map{ |t| Tag.find_by_title(CGI.unescape(t)) }
    if @tags.any?
      # for now:
      self.tag = @tags.first
      self
    else
      super
    end
  end
  
end
