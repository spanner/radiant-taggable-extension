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
  
  # Most of the tags here can be understood as compounds in the form select:display. So eg
  # with coincident_tags:list the 'coincident_tags' part determines the set of tags to be displayed and 
  # the 'list' part determines how they will be presented.
  # 
  # the actual presentation is done by rendering the relevant tags:* tag

  %W{all top page requested coincident}.each do |these|
    
    ################# tag-selection prefixes determine the tag list to be displayed. Exceptions are raised by the list-getters if specific requirements not met.

    desc %{
      Gathers the set of #{these} tags.
      Not usually called directly, but if you want to you can:
        
      *Usage:* 
      <pre><code><r:#{these}_tags><r:tags:cloud /></r:#{these}_tags></code></pre>
      
      is the same as 
      
      <pre><code><r:#{these}_tags:cloud /></code></pre>
      
      but might give you more control.
    }
    tag "#{these}_tags" do |tag|
      tag.locals.tags = send("_get_#{these}_tags".intern, tag)
      tag.expand
    end
    
    ################# conditional tags just check presence of designated tags

    desc %{
      Contents are rendered only if the set of #{these} tags is not empty.

      *Usage:* 
      <pre><code><r:if_#{these}_tags>...</r:if_#{these}_tags></code></pre>
    }    
    tag "if_#{these}_tags" do |tag|
      tag.locals.tags = send("_get_#{these}_tags".intern, tag)
      tag.expand if tag.locals.tags.any?
    end
    
    desc %{
      Contents are rendered only if the set of #{these} tags is empty.

      *Usage:* 
      <pre><code><r:unless_#{these}_tags>...</r:unless_#{these}_tags></code></pre>
    }    
    tag "unless_#{these}_tags" do |tag|
      tag.locals.tags = send("_get_#{these}_tags".intern, tag)
      tag.expand unless tag.locals.tags.any?
    end

    ################# display suffixes pass on to the relevant tags:* method

    desc %{
      Loops through all the #{these} tags.

      *Usage:* 
      <pre><code><r:#{these}_tags:each>...</r:#{these}_tags:each></code></pre>
    }
    tag "#{these}_tags:each" do |tag|
      tag.render('tags:each', tag.attr.dup)
    end

    desc %{
      Returns a list of all the #{these} tags.

      *Usage:* 
      <pre><code><r:#{these}_tags:list /></code></pre>
    }
    tag "#{these}_tags:list" do |tag|
      tag.render('tags:list', tag.attr.dup)
    end

    desc %{
      Returns a cloud of all the #{these} tags.

      *Usage:* 
      <pre><code><r:#{these}_tags:cloud /></code></pre>
    }
    tag "#{these}_tags:cloud" do |tag|
      tag.render('tags:cloud', tag.attr.dup)
    end

    desc %{
      Summarises in a sentence the list of #{these} tags.
      
      *Usage:* 
      <pre><code><r:#{these}_tags:summary /></code></pre>
    }    
    tag "#{these}_tags:summary" do |tag|
      tag.render('tags:summary', tag.attr.dup)
    end
    
    ################# pagey suffixes on to the relevant tags:pages method. only requested_tags is likely to be much used here.
    
    desc %{
      Lists all the pages tagged with #{these} tags, in descending order of overlap.

      *Usage:* 
      <pre><code><r:#{these}_tags:pages:each>...</r:#{these}_tags:pages:each></code></pre>
    }
    tag "#{these}_tags:pages" do |tag|
      tag.locals.pages = Page.from_tags(tag.locals.tags)
      tag.expand
    end
    tag "#{these}_tags:pages:each" do |tag|
      tag.render('pages:each', tag.attr.dup, &tag.block) 
    end

    desc %{
      Renders the contained elements only if there are any pages associated with #{these} tags.

      *Usage:* 
      <pre><code><r:#{these}_tags:if_pages>...</r:#{these}_tags:if_pages></code></pre>
    }
    tag "#{these}_tags:if_pages" do |tag|
      tag.render('tags:if_pages', tag.attr.dup, &tag.block)
    end

    desc %{
      Renders the contained elements only if there are no pages associated with #{these} tags.

      *Usage:* 
      <pre><code><r:#{these}_tags:unless_pages>...</r:#{these}_tags:unless_pages></code></pre>
    }
    tag "#{these}_tags:unless_pages" do |tag|
      tag.render('tags:unless_pages', tag.attr.dup, &tag.block)
    end
  end

  
  
  ################# list-display tags: take a set and display it somehow. Because they're in the tags: namespace they default to tag.locals.page.tags.

  desc %{
    Summarises in a sentence the list of tags currently active.

    <pre><code>Pages tagged with <r:page_tags:summary />:</code></pre>
    
    *Usage:* 
    And the output would be "Pages tagged with tag1, tag2 and tag3:".
  }    
  tag 'tags:summary' do |tag|
    if tag.locals.tags && tag.locals.tags.any?
      options = tag.attr.dup
      tag.locals.tags.map { |t|
        tag.locals.tag = t
        tag.render('tag:link', options)
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

  desc %{
    Renders a tag cloud showing the local tags, with prominence determined by 
    their global importance.

    *Usage:* 
    <pre><code><r:tags:cloud /></code></pre>

    The css classes take the form 'cloud_9' where 9 is the band number and smaller numbers are more prominent.
    By default we allow six bands and unlimited number of tags: you can change that with the bands and limit parameters.

    <pre><code><r:tags:cloud bands="10" limit="1000" /></code></pre>
    
    The 'tagpage' parameter prefixes the link destination for each tag displayed in the cloud. We will 
    append the tag name, expecting the destination to be a TagPage showing a list of tagged items. You can
    also specify a global tags page with a 'tags.page' config entry. Either way, it should be the absolute
    url (eg "/tags").
    
    <pre><code><r:tags:cloud tagpage="/tags" /></code></pre>
    
    If you want a cloud of all the tags in use:
    
    <pre><code><r:all_tags:cloud /></code></pre>
    
    Or all the tags that coincide with the currently-selected set:
    
    <pre><code><r:requested_tags:cloud /></code></pre>

    Or all the tags on this page:
    
    <pre><code><r:page_tags:cloud /></code></pre>

    If you want the tags attached to this page (or another page) and all its descendants, r:tag_cloud is probably more useful.
  }
  
  tag 'tags:cloud' do |tag|
    if tag.locals.tags && tag.locals.tags.any?
      options = tag.attr.dup
      tag.locals.tags = Tag.get_popularity_of(tag.locals.tags).sort_by{|t| t.title.downcase}                          # nb. get_popularity_of immediately returns list if already popularised
      bands = options.delete('bands') || tag.locals.bands || 6
      listclass = options.delete('listclass') || 'cloud'
      show_checkboxes = (options.delete('checkbox') == 'true')
      result = %{<ul class="#{listclass}">}
      tag.locals.tags.each do |t|
        tag.locals.tag = t
        result << %{<li class="cloud_#{tag.render('tag:cloud_band')}">#{tag.render('tag:link', options)}</li>}
      end 
      result << "</ul>"
      result
    else
      "No tags"
    end
  end

  desc %{
    Renders a tag list showing the tags in context.

    *Usage:* 
    <pre><code><r:tags:list /></code></pre>
    
    or for use in a form:
    
    <pre><code><r:tags:list checklist="true" /></code></pre>
    
    in which case we will omit the links, add checkboxes and check them for any requested tags.
      
    The usual tag lists work:
    
    <pre><code>
      <r:all_tags:list />
      <r:page_tags:list />
      <r:requested_tags:list />
      <r:coincident_tags:list />
    </code></pre>
    
    But if you want the tags attached to this page (or another page) and all its descendants, you'll find r:tag_list more helpful.
  }
  
  tag 'tags:list' do |tag|
    if tag.locals.tags && tag.locals.tags.any?
      options = tag.attr.dup
      show_checkboxes = (options.delete('checklist') == 'true')
      listclass = options.delete('listclass') || 'taglist'
      result = %{<ul class="#{listclass}">}
      tag.locals.tags.each do |t|
        tag.locals.tag = t
        if show_checkboxes
          if tag.locals.page.is_a?(TagPage) && tag.locals.page.requested_tags.include?(t)
            checked = ' checked="true"'
            checkedclass = ' class="checked"'
          end
          result << %{<li#{checkedclass}><input type="checkbox" name="tag[]" id="tag_#{t.id}" value=#{t.id}#{checked} />#{tag.render('tag:name')}</li>}
        else
          result << %{<li>#{tag.render('tag:link', options)}</li>}
        end
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
    This is essentially a filtering form: it returns a list of the selected tags, linked so that you can remove them, 
    and a list of the available tags, linked so that you can add them. It only works on a TagPage. 
    
    You can limit the size of the available-tags list in the usual way. The default limit is 40.
    
    *Usage:* 
    <pre><code><r:tag_chooser limit="20" /></code></pre>
    
    The output is roughly equivalent to this:
    
    <pre><code>
      <r:unless_requested_tags>
        <h4>choose a tag</h4>
        <r:top_tags:list limit="6" />
      </r:unless_requested_tags>
      <r:if_requested_tags>
        <h4>remove a tag</h4>
        <ul class="requested">
          <r:requested_tags:each />
            <r:tag:unlink />
          </r:requested_tags:each />
        </ul>
        <h4>add a tag</h4>
        <ul class="possible">
          <r:coincident_tags:each />
            <r:tag:link />
          </r:coincident_tags:each />
        </ul>
      </r:if_requested_tags>
    </code></pre>
  }    
  tag 'tag_chooser' do |tag|
    options = tag.attr.dup
    result = []
    requested_tags = _get_requested_tags(tag)
    if requested_tags.any?
      result << %{<h4>remove a tag</h4>}
      result << %{<ul class="requested">}
      requested_tags.each do |t|
        tag.locals.tag = t
        result << %{<li>#{tag.render('tag:unlink')}</li>}
      end
      result << %{</ul>}
      available_tags = _get_coincident_tags(tag)
      if available_tags.any?
        result << %{<h4>add a tag</h4>}
        result << %{<ul class="available">}
        available_tags.each do |t|
          tag.locals.tag = t
          result << %{<li>#{tag.render('tag:link')}</li>}
        end
        result << %{</ul>}
      end
    else
      result << %{<h4>choose a tag</h4>}
      result << %{<ul class="available">}
      _get_top_tags(tag).each do |t|
        tag.locals.tag = t
        result << %{<li>#{tag.render('tag:link')}</li>}
      end
      result << %{</ul>}
    end
    result
  end

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
    
    <pre><code><r:tag_cloud limit="200" tagpage="/archive" /></code></pre>
    
    If you want to show all the tags in the database, you want r:all_tags:cloud, btw.
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
    
    <pre><code><r:tag_list limit="200" tagpage="/archive" /></code></pre>    
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
  
  desc %{
    Lists all the pages associated with a set of tags, in descending order of relatedness.
    If we can see a 'strict' parameter, only pages tagged with all the specified tags are shown.
    
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
    Makes a link to the current tag. If the current page is a tag page, we amend the 
    list of requested tags. Otherwise, the 'tagpage' parameter cab be the address of a 
    TagPage, or you can specify a global tags page with a 'tags.page' config entry.
    
    If no tagpage is specified we return a relative link to the escaped name of the tag.
    
    *Usage:* 
    <pre><code><r:tag:link tagpage='/tags' /></code></pre>
  }
  tag 'tag:link' do |tag|
    raise TagError, "tag must be defined for tag:link tag" unless tag.locals.tag
    options = tag.attr.dup
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('tag:name')

    if tag.locals.page.is_a?(TagPage)
      href = tag.locals.page.tagged_url(tag.locals.page.requested_tags + [tag.locals.tag])
    elsif page_url = (options.delete('tagpage') || Radiant::Config['tags.page'])
      href = clean_url(page_url + '/' + tag.locals.tag.clean_title)
    else 
      href ||= Rack::Utils.escape("#{tag.locals.tag.title}") + '/'
    end

    %{<a href="#{href}#{anchor}"#{attributes}>#{text}</a>}
  end

  desc %{
    Makes a link that removes the current tag from the active set. Other options as for tag:link.
        
    *Usage:* 
    <pre><code><r:tag:unlink tagpage='/tags' /></code></pre>
  }
  tag 'tag:unlink' do |tag|
    raise TagError, "tag must be defined for tag:unlink tag" unless tag.locals.tag
    options = tag.attr.dup
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : tag.render('tag:name')

    if tag.locals.page.is_a?(TagPage)
      href = tag.locals.page.tagged_url(tag.locals.page.requested_tags - [tag.locals.tag])
    elsif page_url = (options.delete('tagpage') || Radiant::Config['tags.page'])
      href = clean_url(page_url + '/-' + tag.locals.tag.clean_title)
    else 
      href ||= Rack::Utils.escape("-#{tag.locals.tag.title}") + '/'
    end

    %{<a href="#{href}#{anchor}"#{attributes}>#{text}</a>}
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



private

  def _get_tag(tag, options)
    if title = options.delete('title')
      tag.locals.tag ||= Tag.find_by_title(title)
    end
    if tag.locals.page.is_a?(TagPage)
      tag.locals.tag ||= tag.locals.page.requested_tags.first
    end
  end
  
  # this is the default used for bare tags:* tags.
  # among other things it catches the tags="" parameter
  # but change is likely here and anything not documented shouldn't be relied upon.
  
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
  
  def _get_all_tags(tag)
    Tag.find(:all)
  end

  def _get_top_tags(tag)
    limit = tag.attr.delete('limit') || 1000
    Tag.most_popular(limit)
  end
  
  def _get_page_tags(tag)
    raise TagError, "page_tags needs a page" unless tag.locals.page
    tag.locals.page.attached_tags
  end

  def _get_requested_tags(tag)
    raise TagError, "requested_tags tags can only be used on a TagPage" unless tag.locals.page && tag.locals.page.is_a?(TagPage)
    tag.locals.page.requested_tags
  end
  
  def _get_coincident_tags(tag)
    raise TagError, "coincident_tags tag can only be used on a TagPage" unless tag.locals.page && tag.locals.page.is_a?(TagPage)
    tags = tag.locals.page.requested_tags
    Tag.coincident_with(tags) if tags.any?
  end
  
end
