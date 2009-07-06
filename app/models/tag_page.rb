class TagPage < Page

  description %{ Takes a tag name in child position so that tagged items can be listed. }

  attr_accessor :requested_tag, :requested_tags
  
  def find_by_url(url, live = true, clean = false)
    url = clean_url(url) if clean
    tagtitles = url.gsub(/^#{ self.url }\/?/, '').split('/')
    @tags = tagtitles.select{|t| !t.blank? }.map{ |t| Tag.find_by_title(CGI.unescape(t)) }
    if @tags.any?
      # for now:
      self.requested_tag = @tags.first
      self.requested_tags = @tags
      self
    else
      super
    end
  end
  
  def breadcrumb
    if self.requested_tag
      %{<a href="#{self.url}">#{self.breadcrumb}</a> &gt; #{self.requested_tag.title}}
    else
      super
    end
  end
  
end
