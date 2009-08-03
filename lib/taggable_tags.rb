module TaggableTags
  include Radiant::Taggable
  
  class TagError < StandardError; end

  # single tag

  desc %{
    This is the namespace for referencing a single tag. It's not usually called directly, 
    but you can supply a 'title' or 'id' attribute.
    
    *Usage:* 
    <pre><code><r:tag [title="tag_title"]>...</r:tag></code></pre>
  }    
  tag 'tag' do |tag|
    tag.locals.tag ||= _get_tag(tag, tag.attr.dup)
    tag.expand
  end

  desc %{
    Contents are rendered if a tag is currently defined. Useful on a TagPage page where you may or
    may not have received a tag parameter.
    
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
    Shows name of current tag.
    
    *Usage:* 
    <pre><code><r:tag:name /></code></pre>
  }    
  tag 'tag:name' do |tag|    
    raise TagError, "tag must be defined for tag:title tag" unless tag.locals.tag
    tag.locals.tag.title
  end

  desc %{
    Makes a link to the current tag, if possible, or just displays its name.
    
    The 'tagpage' parameter should be the address of a TagPage, or you can specify a 
    global tags page with a 'tags.page' config entry.
    
    Otherwise, sorks the same way as other links. Attributes are passed through, 
    anchor can be set, and if the tag is double then the contained text and/or tags 
    will become the link.
    
    *Usage:* 
    <pre><code><r:tag:link to='/tags' /></code></pre>
  }    
  tag 'tag:link' do |tag|
    raise TagError, "tag must be defined for tag:link tag" unless tag.locals.tag
    options = tag.attr.dup
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('tag:name')
    page_url = options.delete('tagpage') || Radiant::Config['tags.page']
    if page_url
      href = clean_url( "#{page_url}/#{tag.locals.tag.title}" )
      %{<a href="#{href}#{anchor}"#{attributes}>#{text}</a>}
    else
      text
    end
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
    Contents are rendered if the current tag has been applied to any pages.
    
    *Usage:* 
    <pre><code><r:tag:if_pages>...</r:tag:if_pages></code></pre>
  }    
  tag 'tag:if_pages' do |tag|
    tag.expand if tag.locals.tag.pages.any?
  end
  
  desc %{
    Contents are rendered unless the current tag has been applied to any pages.
    
    *Usage:* 
    <pre><code><r:tag:unless_pages>...</r:tag:unless_pages></code></pre>
  }    
  tag 'tag:unless_pages' do |tag|
    tag.expand unless tag.locals.tag.pages.any?
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


  # multiple tags

  desc %{
    Contents are rendered only if a set of tags is available.
    This is useful on a TagPage to decide what form to show, for example, 
    or on a normal page to decide whether to show related pages.
    
    *Usage:* 
    <pre><code><r:if_tags>...</r:if_tags></code></pre>
  }    
  tag 'if_tags' do |tag|
    tag.locals.tags = _get_tags(tag)
    tag.expand if tag.locals.tags.any?
  end
  
  desc %{
    Contents are rendered only if a set of tags is not available.
    This is useful on a TagPage to decide what form to show, for example, 
    or on a normal page to decide whether to show related pages.
    
    *Usage:* 
    <pre><code><r:unless_tags>...</r:unless_tags></code></pre>
  }    
  tag 'unless_tags' do |tag|
    tag.locals.tags = _get_tags(tag)
    tag.expand unless tag.locals.tags.any?
  end
    
  desc %{
    The root 'tags' tag is never used except as part of a construction like tags:each.
  }
  tag 'tags' do |tag|
    raise TagError, "page must be defined for tags tag" unless tag.locals.page
    tag.locals.strict = tag.attr.delete('strict') || (tag.locals.page.is_a?(TagPage) && tag.locals.page.strict_match)
    tag.locals.tags ||= _get_tags(tag)
    tag.expand
  end

  desc %{
    Summarises in a sentence the list of tags currently active.
    A list header might say, for example:

    <pre><code>Pages tagged with <r:tags:summary /> with the best matches first:</code></pre>
    
    And the output would be "tag1, tag2 or tag3". If we can see a 'strict' parameter,
    then the conjunction becomes 'and'. If we can find a link destination (either as a 'tagpage'
    parameter or a tags.page config item) then the tags will be links.
        
  }    
  tag 'tags:summary' do |tag|
    raise TagError, "tags must be defined for tags tag" unless tag.locals.tags
    options = tag.attr.dup
    conjunction = tag.locals.strict ? ' and ' : ' or '
    tag.locals.tags.map { |t|
      tag.locals.tag = t
      tag.render('tag:link', options.dup)
    }.to_sentence(:last_word_connector => conjunction, :two_words_connector => conjunction)
  end

  desc %{
    Cycles through all tags attached to present page or requested by the user.
    You can also specify a set of tags, which is occasionally a useful shortcut
    for building a topic list.

    *Usage:* 
    <pre><code><r:tags:each tags="foo, bar">...</r:tags:each></code></pre>
  }    
  tag 'tags:each' do |tag|
    result = []
    tag.locals.tags.each do |item|
      tag.locals.tag = item
      result << tag.expand
    end 
    result
  end

  desc %{
    Lists all the pages associated with a set of tags, in descending order of relatedness.
    If we can see a 'strict' parameter, only pages tagged with all the specified tags are shown.
    
    *Usage:* 
    <pre><code><r:tagged_pages:each>...</r:tagged_pages:each></code></pre>
  }
  tag 'tagged_pages' do |tag|
    raise TagError, "tags must be defined to use any tagged_pages tag" unless tag.locals.tags
    tag.locals.pages = tag.locals.strict ? Page.from_all_tags(tag.locals.tags) : Page.from_tags(tag.locals.tags)
    tag.expand
  end
  tag 'tagged_pages:each' do |tag|
    result = []
    tag.locals.pages.each do |page|
      tag.locals.page = page
      result << tag.expand
    end 
    result
  end
  
  desc %{
    Renders the contained elements only if there are any pages associated with the current tags.

    *Usage:* 
    <pre><code><r:tagged_pages:if_any>...</r:tagged_pages:if_any></code></pre>
  }
  tag "tagged_pages:if_any" do |tag|
    tag.expand if tag.locals.pages.to_a.any?
  end

  desc %{
    Renders the contained elements only if there are no assets of the specified type in the current set.

    *Usage:* 
    <pre><code><r:tagged_pages:unless_any>...</r:tagged_pages:unless_any></code></pre>
  }
  tag "tagged_pages:unless_any" do |tag|
    tag.expand unless tag.locals.pages.to_a.any?
  end
  
  desc %{
    Lists all the pages similar to this page (based on its tagging), in descending order of relatedness.
    If we can see a 'strict' parameter, only exact matches are shown.
    
    *Usage:* 
    <pre><code><r:related_pages:each>...</r:related_pages:each></code></pre>
  }
  tag 'related_pages' do |tag|
    raise TagError, "page must be defined for related_pages tag" unless tag.locals.page
    tag.locals.pages = tag.locals.page.related_pages
    tag.expand
  end
  tag 'related_pages:each' do |tag|
    result = []
    tag.locals.pages.each do |page|
      tag.locals.page = page
      result << tag.expand
    end 
    result
  end

  desc %{
    Renders a tag cloud showing only the local tags, but with prominence determined by 
    their global importance. If you want a cloud of all the tags in use, use r:tag_cloud.
  }
  # NB all r:tag_cloud does is to gather tags and then call this method
  
  tag 'tags:cloud' do |tag|
    raise TagError, "no tags found for tags:cloud" unless tag.locals.tags
    options = tag.attr.dup
    tag.locals.tags = Tag.get_popularity_of(tag.locals.tags).sort_by{|t| t.title.downcase}
    bands = options.delete('bands') || tag.locals.bands || 6
    listclass = options.delete('listclass') || 'cloud'
    show_checkboxes = options.delete('checkbox') || false
    result = %{<ul class="#{listclass}">}
    tag.locals.tags.each do |t|
      tag.locals.tag = t
      if show_checkboxes
        if tag.locals.page.is_a?(TagPage) && tag.locals.page.requested_tags.include?(t)
          checked = 'checked="true"'
          checkedclass = 'checked'
        end
        checkbox = %{<input type="checkbox" name="tag[]" id="tag_#{t.id}" value=#{t.id} #{checked}" />}
      end
      result << %{<li class="cloud_#{tag.render('tag:cloud_band')} #{checkedclass}">}
      result << checkbox
      result << %{#{tag.render('tag:link', options.dup)}</li>}    #.dup because :link deletes options as it reads them
    end 
    result << "</ul>"
    result
  end


  # all tags. these are mostly shortcuts that set the scene for tags:cloud

  desc %{
    Returns a tag-cloud list showing all the tags attached to this page and its descendants, 
    with cloud band css classes determined by popularity within that group. You can supply a url 
    parameter to work from a page other than the present one. If you want to show all the tags 
    attached to pages:
    
    <pre><code><r:tag_cloud url="/" /></code></pre>
    
    If you want to show all the tags in the database (regardless of their page-attachment), supply all='true':
    
    <pre><code><r:tag_cloud all="true" /></code></pre>

    And if you want to limit the size of the cloud, add a 'limit' parameter to any of these examples:
    
    <pre><code><r:tag_cloud all="true" limit="200" /></code></pre>

    The css classes take the form 'cloud_9' where 9 is the band number and smaller numbers are more prominent.
    By default we allow six bands and 50 tags: you can change those with the bands and limit parameters.
    
    The 'tagpage' parameter prefixes the link destination for each tag displayed in the cloud. We will 
    append the tag name, expecting the destination to be a TagPage showing a list of tagged items. You can
    also specify a global tags page with a 'tags.page' config entry. Either way, it should be the absolute
    url (eg "/tags").
    
    <pre><code>
      <r:tag_cloud [tagpage="/tags"] [url="/"] [limit="50"] [bands="6"] />
    </code></pre>
  }    
  tag 'tag_cloud' do |tag|
    options = tag.attr.dup
    limit = options.delete('limit')
    if options.delete('all')
      tag.locals.tags = Tag.banded(Tag.most_popular(limit))
    else
      if url = options.delete('url')
        found = Page.find_by_url(absolute_path_for(tag.locals.page.url, url))
        raise TagError, "no page at url #{url}" unless page_found?(found)
        tag.locals.page = found
      end
      raise TagError, "no page (or 'all' parameter) for tag_list" unless tag.locals.page
      tag.locals.tags = tag.locals.page.tags_for_cloud(limit)   # page.tags_for_cloud does a lot of inheritance work
    end
    tag.render('tags:cloud', options)
  end

  desc %{
    Returns a list of tags with checkboxes, suitable for choosing several. I'm expecting this to be
    used on a TagPage to choose the set of active tags: for most other purposes a tag cloud is more useful.

    By default we apply cloud band classes. If you don't want that styling you can either ignore it in css
    or pass in bands="false".
    
    The tag selection rules are the same as for the cloud: if you pass in all="true", you get everything. 
    Otherwise you get only tags that are attached to the current page and its descendants (or another page that
    you specify with a url parameter). Limit, bands and tagpage parameters are passed through.
    
    <pre><code>
      <r:tag_list url="/" />
      <r:tag_list [url="/"] [limit="50"] [bands="6"] tagpage="/archive" />
    </code></pre>
  }    
  tag 'tag_list' do |tag|
    options = tag.attr.dup
    limit = options.delete('limit')
    if options.delete('all')
      tag.locals.tags = Tag.banded(Tag.most_popular(limit))
    else
      if url = options.delete('url')
        found = Page.find_by_url(absolute_path_for(tag.locals.page.url, url))
        raise TagError, "no page at url #{url}" unless page_found?(found)
        tag.locals.page = found
      end
      raise TagError, "no page (or 'all' parameter) for tag_list" unless tag.locals.page
      tag.locals.tags = tag.locals.page.tags_for_cloud(limit)   # page.tags_for_cloud does a lot of inheritance work
    end
    options['checkbox'] = true
    options['listclass'] = 'checklist'
    tag.render('tags:cloud', options)
  end
  
  # useful
  
  desc %{
    Shows a link to the target page with a (non-linked) breadcrumb trail to give it context.
    This is the opposite of r:breadcrumbs, which shows a linked trail but doesn't link the current page.
    Link and breadcrumb attributes should work in the usual way, and by default we omit the home page
    from the list since it adds no information. pass omit_root='false' to show the whole chain.
    
    *Usage:* 
    <pre><code><r:tag:pages:each>
      <r:crumbed_link [omit_root="false"] [separator=" &rarr; "] />
      <r:crumbed_link>Link text</r:crumbed_link>
      etc
    </r:tag:pages:each></code></pre>
  }    
  tag 'crumbed_link' do |tag|
    page = tag.locals.page
    ancestors = page.ancestors
    ancestors.pop unless tag.attr['omit_root'] == 'false'
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
      tag.locals.tag ||= tag.locals.page.requested_tags.first
    end
  end
  
  def _get_tags(tag)
    tags = if tag.attr['tags'] && !tag.attr['tags'].blank?
      Tag.from_list(tag.attr['tags'], false)    # false parameter -> not to create missing tags
    elsif tag.locals.page.is_a?(TagPage)
      tag.locals.page.requested_tags
    elsif tag.locals.page
      tag.locals.page.attached_tags
    else
      []
    end
    tags = tags.uniq.select{|t| !t.nil? }
  end  
  
end