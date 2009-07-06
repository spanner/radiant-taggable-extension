module TaggableTags
  include Radiant::Taggable
  
  class TagError < StandardError; end

  desc %{
    Contents are rendered only if the current page has any tags attached.
    
    *Usage:* 
    <pre><code><r:if_tags>...</r:if_tags></code></pre>
  }    
  tag 'if_tags' do |tag|
    tag.expand if tag.locals.page && tag.locals.page.attached_tags.any?
  end
  
  desc %{
    Contents are rendered only if the current page has no tags attached.
    
    *Usage:* 
    <pre><code><r:unless_tags>...</r:unless_tags></code></pre>
  }    
  tag 'unless_tags' do |tag|
    tag.expand unless tag.locals.page && tag.locals.page.attached_tags.any?
  end
  
      
  desc %{
    Cycles through all tags attached to present page
    Takes the same sort and order parameters as children:each
    
    *Usage:* 
    <pre><code><r:tags>...</r:tags></code></pre>
  }    
  tag 'tags' do |tag|
    raise TagError, "page must be defined for page:tags tag" unless tag.locals.page
    tag.expand
  end
  tag 'tags:each' do |tag|
    result = []
    tags = tag.locals.page.attached_tags.find(:all, _find_options(tag))
    tags.each do |item|
      tag.locals.tag = item
      result << tag.expand
    end 
    result
  end
  
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
    Contents are rendered if a tag is currently defined. Useful on a TagPage page where you may or
    may not have a tag parameter.
    
    *Usage:* 
    <pre><code><r:if_tag>...</r:if_tag></code></pre>
  }    
  tag 'if_tag' do |tag|
    tag.locals.tag ||= _get_tag(tag, tag.attr.dup)
    tag.expand if tag.locals.tag
  end
  
  desc %{
    Contents are rendered if no tag is currently defined. Useful on a TagPage page where you may or
    may not have a tag parameter.
    
    *Usage:* 
    <pre><code><r:unless_tag>...</r:unless_tag></code></pre>
  }    
  tag 'unless_tag' do |tag|
    tag.locals.tag ||= _get_tag(tag, tag.attr.dup)
    tag.expand unless tag.locals.tag
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
    tag.expand
  end
  
  desc %{
    Shows name of current tag.
    
    *Usage:* 
    <pre><code><r:tag:name /></code></pre>
  }    
  tag 'tag:name' do |tag|    
    raise TagError, "tag must be defined for tag:title tag" unless tag.locals.tag
    tag.locals.tag.title
  end

  desc %{
    Shows description of current tag.
    
    *Usage:* 
    <pre><code><r:tag:description /></code></pre>
  }    
  tag 'tag:description' do |tag|    
    raise TagError, "tag must be defined for tag:description tag" unless tag.locals.tag
    tag.locals.tag.description
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
    tag.locals.tag.pages.each do |page|
      tag.locals.page = page
      result << tag.expand
    end 
    result
  end

  desc %{
    Returns a tag-cloud list showing all the tags attached to this page and its descendants, 
    with cloud band css classes determined by popularity within that group.
    
    The classes take the form 'cloud_9' where 9 is the band number and smaller numbers should be more prominent.
    By default we allow six bands and 50 tags: you can change those with the bands and limit parameters,
    and you can supply a url parameter to start from a page other than the present one.
    
    The 'destination' parameter sets the link destination for each tag displayed in the cloud. We will 
    append the tag name, expecting that it will be a TagPage showing a list of tagged items. The default
    is /tags (and so we link to /tags/name), but that won't work unless you've set it up.
    
    <pre><code>
      <r:page:tag_cloud [destination="/tags"] [url="/"] [limit="50"] [bands="6"] />
    </code></pre>
    
    If the tag is double then we render its contents for each tag, omit the enclosing <ul>, and ignore the 
    destination parameter:
    
    <pre><code>
      <ol class="my_cloud">
        <r:tag_cloud>
          <li class="<r:tag:cloud_band />">...</li>
        </r:page:tag_cloud>
      </ol>
    </code></pre>
  }    
  tag 'tag_cloud' do |tag|
    
    unless tag.locals.tags
      if tag.attr['url']
        found = Page.find_by_url(absolute_path_for(tag.locals.page.url, tag.attr['url']))
        tag.locals.page = found if page_found?(found)
      end
      raise TagError, "tags or page must be present for tag_cloud tag" unless tag.locals.page
      limit = tag.attr['limit'] || 50
      tag.locals.tags = tag.locals.page.tags_for_cloud(limit)   # page.tags_for_cloud does a lot of inheritance work
    end

    bands = tag.attr['bands'] || 6
    destination = tag.attr['destination'] || Radiant::Config['tags.page'] || '/tags'
    
    if tag.locals.tags
      result = tag.double? ? "" : %{<ul class="cloud">}
      tag.locals.tags.each do |t|
        if tag.double?
          tag.locals.tag = t
          result << tag.expand
        else
          href = clean_url( "#{destination}/#{t.title}" )
          result << %{<li class="cloud_#{t.cloud_band}"><a href="#{href}">#{t.title}</a></li>}
        end
      end 
      result << "</ul>" unless tag.double?
    end
    result
  end
  
  desc %{
    Shows a link to the target page with a (non-linked) breadcrumb trail to give it context.
    This is the opposite of r:breadcrumbs, which shows a linked trail but doesn't link the current page.
    Link and breadcrumb attributes should work in the usual way, and you can pass an 'omit_first' parameter 
    if you don't want the site home page to feature in every link.
    
    *Usage:* 
    <pre><code><r:tag:pages:each>
      <r:crumbed_link [omit_root="true"] [separator=" &rarr; "] />
      <r:crumbed_link>Link text</r:crumbed_link>
      etc
    </r:tag:pages:each></code></pre>
  }    
  tag 'crumbed_link' do |tag|
    page = tag.locals.page
    ancestors = page.ancestors
    ancestors.pop if tag.attr['omit_root']
    breadcrumbs = [tag.render('link')]
    ancestors.each do |ancestor|
      tag.locals.page = ancestor
      breadcrumbs.unshift tag.render('breadcrumb')
    end
    separator = tag.attr['separator'] || ' &gt; '
    breadcrumbs.join(separator)
  end
  
  
  
  
  

private
  
  # ok, so the terminology gets a bit squashed here.
  # and we have to be careful not to stamp on the tag variable.
    
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
    if title = options.delete('title')
      tag.locals.tag ||= Tag.find_by_title(title)
    end
    if tag.locals.page.is_a?(TagPage)
      tag.locals.tag ||= tag.locals.page.requested_tag 
    end
  end
  
  def _get_tags(tag)
    tags = []
    tags = Tag.from_list(tag.attr['tags']) if tag.attr['tags'] && !tag.attr['tags'].blank?
    tags ||= tag.locals.page.attached_tags if tags.empty? && tag.locals.page
    raise TagError, "can't find any tags" if tags.empty?
    tags
  end  
  
end