module TaggableTags
  include Radiant::Taggable
  
  class TagError < StandardError; end

  # tag sets.

  desc %{
    The root 'tags' is not usually called directly. 
    All it does is default to the list of page tags.
    Most tags:* methods are called indirectly: eg 'requested_tags:list'
    will set context to the requested tags and then render tags:list.
    In that case we just oblige by expanding.
  }
  tag 'tags' do |tag|
    tags ||= _get_tags(tag);
    tag.expand
  end
  
  desc %{
    Contents are rendered only if a set of tags is available.
    
    *Usage:* 
    <pre><code><r:if_tags>...</r:if_tags></code></pre>
  }    
  tag 'if_tags' do |tag|
    tag.expand if tag.locals.tags && tag.locals.tags.any?
  end
  
  desc %{
    Contents are rendered only if no set of tags is available.
    
    *Usage:* 
    <pre><code><r:unless_tags>...</r:unless_tags></code></pre>
  }    
  tag 'unless_tags' do |tag|
    tag.expand unless tag.locals.tags && tag.locals.tags.any?
  end
  
  ################# list-display tags: take a set and display it somehow. Because they're in the tags: namespace they default to tag.locals.page.tags.

  desc %{
    Summarises in a sentence the list of tags currently active.

    *Usage:* 
    <pre><code>Pages tagged with <r:tags:summary />:</code></pre>
    
    And the output would be "Pages tagged with tag1, tag2 and tag3:".
  }    
  tag 'tags:summary' do |tag|
    if tag.locals.tags && tag.locals.tags.any?
      options = tag.attr.dup
      tag.locals.tags.map { |t|
        tag.locals.tag = t
        tag.render('tag:unlink', options)
      }.to_sentence
    else
      "no tags"
    end
  end

  desc %{
    Cycles through all tags in context. You can also specify a set of tags, which is occasionally 
    a useful shortcut for building a topic list.

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


  # These are never called directly: but are separated here to dry out the tag handling
  # see r:tag_cloud, or in the library extension, compound forms like r:coincident_tags:tag_cloud and r:requested_tags:list
  # same goes for r:tags:summary but that's occasionally useful on a page too.
  
  tag 'tags:cloud' do |tag|
    if tag.locals.tags && tag.locals.tags.length > 1
      options = tag.attr.dup
      tag.locals.tags = Tag.for_cloud(tag.locals.tags).sort_by{|t| t.title.downcase}                          # nb. for_cloud immediately returns list if already sized
      listclass = options.delete('listclass') || 'cloud'
      show_checkboxes = (options.delete('checkbox') == 'true')
      result = %{<ul class="#{listclass}">}
      tag.locals.tags.each do |t|
        tag.locals.tag = t
        result << %{<li>}
        linktype = options.delete('unlink') ? 'unlink' : 'link'
        result << tag.render("tag:#{linktype}", options.merge('style' => "font-size: #{t.cloud_size.to_f * 2.5}em; opacity: #{t.cloud_size};"))
        result << %{</li>}
      end 
      result << "</ul>"
      result
    else
      "No tags"
    end
  end
  
  tag 'tags:list' do |tag|
    if tag.locals.tags && tag.locals.tags.any?
      options = tag.attr.dup
      show_checkboxes = (options.delete('checklist') == 'true')
      listclass = options.delete('listclass') || 'taglist'
      result = %{<ul class="#{listclass}">}
      tag.locals.tags.each do |t|
        tag.locals.tag = t
        result << %{<li>#{tag.render('tag:link', options)}</li>}
      end 
      result << "</ul>"
      result
    else
      "No tags"
    end
  end



  ################# page-candy: these are high level tags that bring in a whole block of stuff. 
                  # most can be built out of the smaller tags if you need them to work differently

  desc %{
    Returns a tag-cloud showing all the tags attached to this page and its descendants, 
    with cloud band css classes determined by popularity *within the group*. This is intended as a way to
    show what subjects are relevant here, as in the original delicio.us tag clouds. You can achieve similar 
    results with tags like r:all_tags:cloud, but with important differences:
    
    * here prominence depends on popularity within the retrieved set of tags (not overall)
    * here we climb down the page tree to build the set of tags: useful for eg. a section front page.
    
    *Usage:* 
    <pre><code><r:tag_cloud /></code></pre>
    
    You can supply a url parameter to work from a page other than the present one. 
    
    <pre><code><r:tag_cloud url="/elsewhere" /></code></pre>

    So if you want to show all the tags attached to any page (but ignore their attachment to anything else):
    
    <pre><code><r:tag_cloud url="/" /></code></pre>
        
    As usual you can limit the size of the cloud (the most popular will be shown) and set the destination of tag links:
    
    <pre><code><r:tag_cloud limit="200" linkto="/archive" /></code></pre>
  }    
  tag 'tag_cloud' do |tag|
    options = tag.attr.dup
    limit = options.delete('limit')
    if url = options.delete('url')
      found = Page.find_by_url(absolute_path_for(tag.locals.page.url, url))
      raise TagError, "no page at url #{url}" unless page_found?(found)
      tag.locals.page = found
    end
    raise TagError, "no page for tag_cloud" unless tag.locals.page
    tag.locals.tags = tag.locals.page.tags_for_cloud(limit)   # page.tags_for_cloud does a lot of inheritance work
    tag.render('tags:cloud', options)
  end

  desc %{
    Returns a list of tags showing all the tags attached to this page and its descendants. It's essentially the same
    as the tag cloud without the band formatting, but accepts the same options as tags:list.
    
    *Usage:* 
    <pre><code><r:tag_list /></code></pre>
    
    As usual you can limit the size of the list (the most popular will be shown) and set the destination of tag links:
    
    <pre><code><r:tag_list limit="200" linkto="/archive" /></code></pre>    
  }    
  tag 'tag_list' do |tag|
    options = tag.attr.dup
    limit = options.delete('limit')
    if url = options.delete('url')
      found = Page.find_by_url(absolute_path_for(tag.locals.page.url, url))
      raise TagError, "no page at url #{url}" unless page_found?(found)
      tag.locals.page = found
    end
    raise TagError, "no page for tag_list" unless tag.locals.page
    tag.locals.tags = tag.locals.page.tags_for_cloud(limit)   # page.tags_for_cloud does a lot of inheritance work
    tag.render('tags:list', options)
  end
  
  
  
  ################# tagged pages. Other extensions define similar tags for eg tagged assets.
  
  # general purpose pages lister
  
  desc %{
    This is a general purpose page lister. It wouldn't normally be accessed directly but a lot of other tags make use of it.
  }
  tag 'page_list' do |tag|
    raise TagError, "no pages for page_list" unless tag.locals.pages
    result = []
    tag.locals.pages.each do |page|
      tag.locals.page = page
      result << tag.expand
    end 
    result
  end
  
  desc %{
    Lists all the pages associated with a set of tags, in descending order of relatedness.
    
    *Usage:* 
    <pre><code><r:tags:pages:each>...</r:tags:pages:each></code></pre>
  }
  tag 'tags:pages' do |tag|
    tag.locals.pages = Page.from_tags(tag.locals.tags)
    tag.expand
  end
  tag 'tags:pages:each' do |tag|
    tag.render('pages:each', tag.attr.dup, &tag.block)
  end
  
  desc %{
    Renders the contained elements only if there are any pages associated with the current set of tags.

    *Usage:* 
    <pre><code><r:tags:if_pages>...</r:tags:if_pages></code></pre>
  }
  tag "tags:if_pages" do |tag|
    tag.locals.pages = Page.from_tags(tag.locals.tags)
    tag.expand if tag.locals.pages.to_a.any?
  end

  desc %{
    Renders the contained elements only if there are no pages associated with the current set of tags.

    *Usage:* 
    <pre><code><r:tags:unless_pages>...</r:tags:unless_pages></code></pre>
  }
  tag "tags:unless_pages" do |tag|
    tag.locals.pages = Page.from_tags(tag.locals.tags)
    tag.expand unless tag.locals.pages.to_a.any?
  end
  
  # just a shortcut, but a useful one
  
  desc %{
    Lists all the pages similar to this page (based on its tagging), in descending order of relatedness.
    
    *Usage:* 
    <pre><code><r:related_pages:each>...</r:related_pages:each></code></pre>
  }
  tag 'related_pages' do |tag|
    raise TagError, "page must be defined for related_pages tag" unless tag.locals.page
    tag.locals.pages = tag.locals.page.related_pages
    tag.expand
  end
  tag 'related_pages:each' do |tag|
    tag.render('pages:each', tag.attr.dup, &tag.block)
  end
  
  
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



  ################# single tag expansion for simple lists of tagged items or for customised display of each item in a list or cloud context

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
    Contents are rendered if a tag is currently defined. Useful on a LibraryPage page where you may or
    may not have received a tag parameter.
    
    *Usage:* 
    <pre><code><r:if_tag>...</r:if_tag></code></pre>
  }    
  tag 'if_tag' do |tag|
    tag.locals.tag ||= _get_tag(tag, tag.attr.dup)
    tag.expand if tag.locals.tag
  end
  
  desc %{
    Contents are rendered if no tag is currently defined. Useful on a LibraryPage page where you may or
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
    Makes a link to the current tag. If the current page is a library page, we amend the 
    list of requested tags. Otherwise, the 'linkto' parameter can be the address of a 
    LibraryPage, or you can specify a global tags page with a 'library.path' config entry.
    
    If no destination is specified we return a relative link to the escaped name of the tag.
    
    *Usage:* 
    <pre><code><r:tag:link linkto='/library' /></code></pre>
  }
  tag 'tag:link' do |tag|
    raise TagError, "tag must be defined for tag:link tag" unless tag.locals.tag
    options = tag.attr.dup
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('tag:name')
    if tag.locals.page.is_a? LibraryPage
      tagset = tag.locals.page.requested_tags + [tag.locals.tag]
      destination = tag.locals.page.url(tagset)
    elsif page_url = (options.delete('linkto') || Radiant::Config['library.path'])
      destination = clean_url(page_url + '/' + tag.locals.tag.clean_title)
    else
      # note that this only works if you're at a url with a trailing slash...
      destination = Rack::Utils.escape("#{tag.locals.tag.title}") + '/'
    end
    %{<a href="#{destination}#{anchor}"#{attributes}>#{text}</a>}
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



private

  def _get_tag(tag, options)
    if title = options.delete('title')
      tag.locals.tag ||= Tag.find_by_title(title)
    end
    if tag.locals.page.respond_to? :requested_tags
      tag.locals.tag ||= tag.locals.page.requested_tags.first
    end
    tag.locals.tag
  end
  
  # this is the default used for bare tags:* tags.
  # among other things it catches the tags="" attribute
  # but change is likely here and anything not documented shouldn't be relied upon.
  
  def _get_tags(tag)
    tags = if tag.attr['tags'] && !tag.attr['tags'].blank?
      Tag.from_list(tag.attr['tags'], false)    # false parameter -> not to create missing tags
    elsif tag.locals.page.respond_to?(:requested_tags)
      tag.locals.page.requested_tags
    elsif tag.locals.page
      tag.locals.page.attached_tags
    else
      []
    end
    tags = tags.uniq.select{|t| !t.nil? }
  end  

end
