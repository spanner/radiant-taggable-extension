module TaggableTags
  include Radiant::Taggable
  
  class TagError < StandardError; end
  
  desc %{
    The namespace for your collections of tags. Only really useful as tags:each
    
    *Usage:* 
    <pre><code><r:tags>...</r:tags></code></pre>
  }    
  tag 'tags' do |tag|
    tag.expand
  end
  
  desc %{
    Cycles through all tags
    Takes the same parameters as children:each
    
    *Usage:* 
    <pre><code><r:tags:each>...</r:tags:each></code></pre>
  }    
  tag 'tags:each' do |tag|
    result = []
    tags = Tag.find(:all, _find_options(tag))
    tags.each do |item|
      tag.locals.tag = item
      result << tag.expand
    end 
    result
  end
  
  desc %{
    Cycles through all tags attached to present page
    Takes the same sort and order parameters as children:each
    
    *Usage:* 
    <pre><code><r:page:tags>...</r:page:tags></code></pre>
  }    
  tag 'page:tags' do |tag|
    raise TagError, "page must be defined for page:tags tag" unless tag.locals.page
    tag.expand
  end
  tag 'page:tags:each' do |tag|
    result = []
    tags = tag.locals.page.attached_tags.find(:all, _find_options(tag))
    tags.each do |item|
      tag.locals.tag = item
      result << tag.expand
    end 
    result
  end
    
  # related pages
  
  desc %{
    Cycles through related pages in descending order of relatedness
    
    *Usage:* 
    <pre><code><r:related_pages:each>...</r:related_pages:each></code></pre>
  }    
  tag 'related_pages' do |tag|
    raise TagError, "page must be defined for related_pages tag" unless tag.locals.page
    tag.expand
  end
  tag 'related_pages:each' do |tag|
    result = []
    tag.locals.page.related_pages.each do |page|
      tag.locals.page = page
      result << tag.expand
    end 
    result
  end

  desc %{
    The namespace for referencing a single tag. You can supply a 'title' or 'id'
    attribute on this tag for all contained tags to refer to that tag, or
    allow the tag to be defined by tags:each or page:tags.
    
    *Usage:* 
    <pre><code><r:tag [title="tag_title"]>...</r:tag></code></pre>
  }    
  tag 'tag' do |tag|
    tag.locals.tag ||= _get_tag(tag, tag.attr.dup)
  end
  
  desc %{
    Shows name of current tag.
    
    *Usage:* 
    <pre><code><r:tag:title /></code></pre>
  }    
  tag 'tag:title' do |tag|
    raise TagError, "tag must be defined for tag:title tag" unless tag.locals.tag
    tag.locals.tag.title
  end

  desc %{
    Shows cloud_band of current tag (which will normally only be set if we're within a tag_cloud tag)
    
    *Usage:* 
    <pre><code><r:tag:cloud_band /></code></pre>
  }    
  tag 'tag:cloud_band' do |tag|
    raise TagError, "tag must be defined for tag:cloud_band tag" unless tag.locals.tag
    tag.locals.tag.cloud_band
  end

  desc %{
    Shows use_count of current tag (which will normally only be set if we're within a tag_cloud tag)
    
    *Usage:* 
    <pre><code><r:tag:use_count /></code></pre>
  }    
  tag 'tag:use_count' do |tag|
    raise TagError, "tag must be defined for tag:use_count tag" unless tag.locals.tag
    tag.locals.tag.use_count
  end

  desc %{
    Loops through the pages to which this tag has been applied
    setting page context for all contained tags. Works just like children:each 
    or other page tags.
    
    *Usage:* 
    <pre><code><r:tag:pages:each>...</r:tag:pages:each></code></pre>
  }    
  tag 'tag:pages' do |tag|
    raise TagError, "tag must be defined for tag:pages tag" unless tag.locals.tag
    tag.expand
  end
  tag 'tag:pages:each' do |tag|
    result = []
    pages = tag.locals.tag.pages.find(:all, _find_options(tag, Page))
    pages.each do |item|
      tag.locals.page = item
      result << tag.expand
    end 
    result
  end

  

  desc %{
    Returns a tag-cloud list showing all the tags attached to this page and its descendants, 
    with cloud band css classes determined by popularity within that group.
    
    The classes take the form 'cloud_9' where 9 is the band number and larger is bigger.
    By default we allow six bands and 50 tags: you can change those with the bands and limit parameters,
    and you can supply a url parameter to start from a page other than the present one.
    
    The 'destination' parameter sets the link destination for each tag displayed in the cloud. We will pass
    the tag id to it, expecting that it will be a TagPage showing a list of tagged items. The default
    is /tags (and so we link to /tags/:id), but that won't work unless you've set it up.
    
    <pre><code>
      <r:page:tag_cloud [destination="/tags"] [url="/"] [limit="50"] [bands="6"] />
    </code></pre>
    
    If the tag is double then we render its contents for each tag, omit the enclosing <ul>, and ignore the 
    destination parameter:
    
    <pre><code>
      <ol class="my_cloud">
        <r:page:tag_cloud>
          <li class="<r:tag:cloud_band />">...</li>
        </r:page:tag_cloud>
      </ol>
    </code></pre>
  }    
  tag 'page:tag_cloud' do |tag|
    page = tag.locals.page
    raise TagError, "page must be present for page:tag_cloud tag" unless page
    limit = tag.attr['limit'] || 50
    bands = tag.attr['bands'] || 6
    destination = tag.attr['destination'] || '/tags'
    tags = tag.locals.page.tags_for_cloud(limit)
    result = tag.double? ? "" : %{<ul class="cloud">}
    tags.each do |t|
      if tag.double?
        tag.locals.tag = t
        result << tag.expand
      else
        result << %{<li class="cloud_#{t.cloud_band}"><a href="#{destination}/#{t.id}">#{t.title}</a></li>}
      end
    end 
    result << "</ul>" unless tag.double?
    result
  end





private
  
  def _find_options(tag, model=Tag)
    attr = tag.attr.symbolize_keys
  
    options = {}
  
    [:limit, :offset].each do |symbol|
      if number = attr[symbol]
        if number =~ /^\d{1,4}$/
          options[symbol] = number.to_i
        else
          raise TagError.new("`#{symbol}' attribute of `each' tag must be a positive number between 1 and 4 digits")
        end
      end
    end
  
    by = (attr[:by] || 'title').strip
    order = (attr[:order] || 'asc').strip
    order_string = ''
    if model.column_names.include?(by)
      order_string << by
    else
      raise TagError.new("`by' attribute of `each' tag must be set to a valid field name")
    end
    if order =~ /^(asc|desc)$/i
      order_string << " #{$1.upcase}"
    else
      raise TagError.new(%{`order' attribute of `each' tag must be set to either "asc" or "desc"})
    end
    options[:order] = order_string
  
    options
  end

  def _get_tag(tag, options)
    raise TagError, "'title' attribute required" unless title = options.delete('title') or id = options.delete('id') or tag.locals.tag
    tag.locals.tag || Tag.find_by_title(title) || Tag.find(id)
  end
  
  def _get_tags(tag)
    tags = []
    tags = Tag.from_list(tag.attr['tags']) if tag.attr['tags'] && !tag.attr['tags'].blank?
    tags ||= tag.locals.page.attached_tags if tags.empty? && tag.locals.page
    raise TagError, "can't find any tags" if tags.empty?
    tags
  end  
  
end