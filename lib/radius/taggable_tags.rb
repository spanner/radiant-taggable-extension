module Radius
  module TaggableTags
    include Radiant::Taggable
    include TaggableHelper
    
    class TagError < StandardError; end
      
    ################# general purpose lister utilities and dryers-out
                    # can be contained or nested within any list-defining tag
                    # eg.<r:structural_tags:each_tag>...
                    # or just.<r:tags:each_tag>... (aka r:tags:each)

    desc %{
      Contents are rendered only if tags are available to display.
    
      <pre><code><r:if_tags>...</r:if_tags></code></pre>

      Can also be nested inside a set-definition container tag:

      <pre><code><r:structural_tags:if_tags>...</r:structural_tags:if_tags></code></pre>
    }    
    tag 'if_tags' do |tag|
      tag.locals.tags ||= _get_tags(tag)
      tag.expand if tag.locals.tags && tag.locals.tags.any?
    end
  
    desc %{
      Contents are rendered only if no tags are available.
      Can also be nested inside a set-definition container tag.
    }    
    tag 'unless_tags' do |tag|
      tag.locals.tags ||= _get_tags(tag)
      tag.expand unless tag.locals.tags && tag.locals.tags.any?
    end

    desc %{
      Loops through the current list of tags.
      Only works when nested within a set-defining tag.
    }    
    tag "each_tag" do |tag|
      result = []
      tag.locals.tags.each do |item|
        tag.locals.tag = item
        result << tag.expand
      end 
      result
    end

    desc %{
      Displays a UL of the current list of tags.
      Only works when nested within a set-defining tag.
    }    
    tag "tag_list" do |tag|
      if tag.locals.tags && tag.locals.tags.any?
        options = tag.attr.dup
        show_checkboxes = (options.delete('checklist') == 'true')
        listclass = options.delete('listclass') || 'taglist'
        result = %{<ul class="#{listclass}">}
        tag.locals.tags.each do |t|
          tag.locals.tag = t
          result << %{<li>#{tag.render('tag_link', options)}</li>}
        end 
        result << "</ul>"
        result
      else
        "No tags"
      end
    end

    desc %{
      Builds a cloud to display the current list of tags.
      Only works when nested within a set-defining tag.
      For simple page tag-clouding use r:tags:cloud.
    }    
    tag "tag_cloud" do |tag|
      if tag.locals.tags && tag.locals.tags.length > 1
        options = tag.attr.dup
        tag.locals.tags = Tag.for_cloud(tag.locals.tags).sort
        result = []
        result << %{<div class="cloud">}
        tag.locals.tags.sort.each do |t|
          tag.locals.tag = t
          result << tag.render("tag_link", options.merge('style' => "font-size: #{t.cloud_size.to_f * 2.5}em;"))
        end 
        result << "</div>"
        result.join(" ")
      else
        "No tags"
      end
    end

    desc %{
      Summarises in a sentence the current list of tags.
      Only works when nested within a set-defining tag.
    }    
    tag "tag_summary" do |tag|
      if tag.locals.tags && tag.locals.tags.any?
        options = tag.attr.dup
        tag.locals.tags.map { |t|
          tag.locals.tag = t
          tag.render('tag:title', options)
        }.to_sentence
      else
        "no tags"
      end
    end


    ################# set-defining tags are meant to contain clouds and summaries and lists and so on
                    # there are many more in the library
                  

    tag 'structural_tags' do |tag|
      tag.locals.tags = tag.locals.page.attached_tags.structural.visible
      tag.expand
    end

    tag 'all_structural_tags' do |tag|
      tag.locals.tags = Tag.structural.visible
      tag.expand
    end

    tag 'descriptive_tags' do |tag|
      tag.locals.tags = tag.locals.page.attached_tags.descriptive.visible
      tag.expand
    end

    tag 'all_descriptive_tags' do |tag|
      tag.locals.tags = Tag.descriptive.visible
      tag.expand
    end

    tag 'hidden_tags' do |tag|
      tag.locals.tags = tag.locals.page.attached_tags.hidden
      tag.expand
    end

    tag 'all_hidden_tags' do |tag|
      tag.locals.tags = Tag.hidden.visible
      tag.expand
    end

    ################# page-tag shortcuts call the above listers and clouders after first defaulting to 
                    # current page tags (or in the case of the clouds and lists, page and descendants)

    tag 'tags' do |tag|
      tag.expand
    end

    tag 'tags:summary' do |tag|
      tag.locals.tags ||= _get_tags(tag)
      tag.render('tag_summary', tag.attr.dup)
    end

    tag 'tags:each' do |tag|
      tag.locals.tags ||= _get_tags(tag)
      tag.render('each_tag', tag.attr.dup, &tag.block)
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
    
      <pre><code><r:tags:cloud limit="200" linkto="/archive" /></code></pre>
    }    
    tag 'tags:cloud' do |tag|
      tag.locals.tags ||= _get_tags(tag)
      options = tag.attr.dup
      limit = options.delete('limit')
      if url = options.delete('url')
        found = Page.find_by_url(absolute_path_for(tag.locals.page.url, url))
        raise TagError, "no page at url #{url}" unless page_found?(found)
        tag.locals.page = found
      end
      raise TagError, "no page for tag_cloud" unless tag.locals.page
      tag.locals.tags = tag.locals.page.tags_for_cloud(limit).sort   # page.tags_for_cloud does a lot of inheritance work
      tag.render('tag_cloud', options)
    end

    desc %{
      Returns a list of tags showing all the tags attached to this page and its descendants. It's essentially the same
      as the tag cloud without the band formatting.
    
      *Usage:* 
      <pre><code><r:tag_list /></code></pre>
    
      As usual you can limit the size of the list (the most popular will be shown) and set the destination of tag links:
    
      <pre><code><r:tag_list limit="200" linkto="/archive" /></code></pre>    
    }    
    tag 'tags:list' do |tag|
      tag.locals.tags ||= _get_tags(tag)
      options = tag.attr.dup
      limit = options.delete('limit')
      if url = options.delete('url')
        found = Page.find_by_url(absolute_path_for(tag.locals.page.url, url))
        raise TagError, "no page at url #{url}" unless page_found?(found)
        tag.locals.page = found
      end
      raise TagError, "no page for tag_list" unless tag.locals.page
      tag.locals.tags = tag.locals.page.tags_for_cloud(limit).sort
      tag.render('tags:list', options)
    end
  
  
  
  
  
  
    ################# tagged pages. Other extensions define similar tags for eg tagged assets.
    
    tag 'page_list' do |tag|
      raise TagError, "no pages for page_list" unless tag.locals.pages
      result = []
      options = children_find_options(tag)
      paging = pagination_find_options(tag)
      displayed_children = paging ? tag.locals.pages.paginate(options.merge(paging)) : tag.locals.pages.all(options)
      displayed_children.each do |item|
        tag.locals.page = item
        result << tag.expand
      end
      result
    end
  
    desc %{
      Lists all the pages associated with a set of tags, in descending order of relatedness.
    
      *Usage:* 
      <pre><code><r:tagged_pages:each>...</r:tags:pages:each></code></pre>
    }
    tag 'tagged_pages' do |tag|
      tag.locals.pages = Page.from_tags(tag.locals.tags)
      tag.expand
    end
  
    tag 'tagged_pages:each' do |tag|
      tag.render('page_list', tag.attr.dup, &tag.block)
    end
  
    desc %{
      Renders the contained elements only if there are any pages associated with the current set of tags.

      <pre><code><r:if_tagged_pages>...</r:if_tagged_pages></code></pre>
    
      Can be nested in any set-defining tag:
    
      <pre><code><r:requested_tags:if_tagged_pages>...</r:requested_tags:if_tagged_pages></code></pre>
    }
    tag "if_tagged_pages" do |tag|
      tag.locals.pages = Page.from_tags(tag.locals.tags)
      tag.expand if tag.locals.pages.to_a.any?
    end

    desc %{
      Renders the contained elements only if there are no pages associated with the current set of tags.

      *Usage:* 
      <pre><code><r:unless_tagged_pages>...</r:unless_tagged_pages></code></pre>
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
      tag.locals.pages = tag.locals.page.related_pages
      tag.expand
    end
    tag 'related_pages:each' do |tag|
      tag.render('page_list', tag.attr.dup, &tag.block)
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

    tag 'tags:pages' do |tag|
      tag.render('tagged_pages', tag.attr.dup, &tag.block)
    end
  
    tag "tags:if_pages" do |tag|
      tag.render('if_tagged_pages', tag.attr.dup, &tag.block)
    end

    tag "tags:unless_pages" do |tag|
      tag.render('unless_tagged_pages', tag.attr.dup, &tag.block)
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
      raise TagError, "tag must be defined for tag:name tag" unless tag.locals.tag
      tag.locals.tag.title
    end

    desc %{
      Sets context to the page association of the current tag
      (that is, the page towards which this tag is a pointer, if any)

      If there is no page, nothing is displayed.
    
      <pre><code><r:tag:page><r:link /></r:tag:page></code></pre>
    }    
    tag 'tag:page' do |tag|    
      raise TagError, "tag must be defined for tag:page tag" unless tag.locals.tag
      tag.expand if tag.locals.page = tag.locals.tag.page
    end

    desc %{
      Makes a link to the current tag. If the current page is a library page, we amend the 
      list of requested tags. Otherwise, the 'linkto' parameter can be the address of a 
      LibraryPage, or you can specify a global tags page with a 'library.path' config entry.
    
      If no destination is specified we return a relative link to the escaped name of the tag.
    
      *Usage:* 
      <pre><code><r:tag_link linkto='/library' /></code></pre>
    }
    tag 'tag_link' do |tag|
      raise TagError, "tag must be defined for tag_link tag" unless tag.locals.tag
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
      options = children_find_options(tag)
      tag.locals.pages = tag.locals.tag.pages.scoped(options)
      if paging = pagination_find_options(tag)
        tag.locals.pages = tag.locals.pages.paginate(paging)
      end
      tag.locals.pages.each do |page|
        tag.locals.page = page
        result << tag.expand
      end
      result
    end

    ############### asset-listing equivalents of page tags
                  # the main use for these tags is to pull related images and documents into pages
                  # in the same way as you would pull in related pages
  
    desc %{
      Lists all the assets associated with a set of tags, in descending order of relatedness.
      We default to the set of tags attached to this page.
    
      *Usage:* 
      <pre><code><r:tags:assets:each>...</r:tags:assets:each></code></pre>
    }
    tag 'tags:assets' do |tag|
      tag.expand
    end
    tag 'tags:assets:each' do |tag|
      tag.locals.assets ||= _asset_finder(tag)
      tag.render('asset_list', tag.attr.dup, &tag.block)
    end

    desc %{
      Renders the contained elements only if there are any assets associated with the current set of tags.

      *Usage:* 
      <pre><code><r:tags:if_assets>...</r:tags:if_assets></code></pre>
    }
    tag "tags:if_assets" do |tag|
      tag.locals.assets = _assets_for_tags(tag.locals.tags)
      tag.expand if tag.locals.assets.any?
    end

    desc %{
      Renders the contained elements only if there are no assets associated with the current set of tags.

      *Usage:* 
      <pre><code><r:tags:unless_assets>...</r:tags:unless_assets></code></pre>
    }
    tag "tags:unless_assets" do |tag|
      tag.locals.assets = _assets_for_tags(tag.locals.tags)
      tag.expand unless tag.locals.assets.any?
    end
  
    desc %{
      Lists all the assets similar to this page (based on its tagging), in descending order of relatedness.
    
      *Usage:* 
      <pre><code><r:related_assets:each>...</r:related_assets:each></code></pre>
    }
    tag 'related_assets' do |tag|
      raise TagError, "page must be defined for related_assets tag" unless tag.locals.page
      tag.locals.assets = Asset.not_furniture.from_tags(tag.locals.page.attached_tags)
      tag.expand
    end
    tag 'related_assets:each' do |tag|
      tag.render('asset_list', tag.attr.dup, &tag.block)
    end
  
    Asset.known_types.each do |type|
      desc %{
        Lists all the #{type} assets similar to this page (based on its tagging), in descending order of relatedness.

        *Usage:* 
        <pre><code><r:related_#{type.to_s.pluralize}:each>...</r:related_#{type.to_s.pluralize}:each></code></pre>
      }
      tag "related_#{type.to_s.pluralize}" do |tag|
        raise TagError, "page must be defined for related_#{type.to_s.pluralize} tag" unless tag.locals.page
        tag.locals.assets = Asset.not_furniture.from_tags(tag.locals.page.attached_tags).send("#{type.to_s.pluralize}".intern)
        tag.expand
      end
      tag "related_#{type.to_s.pluralize}:each" do |tag|
        tag.render('asset_list', tag.attr.dup, &tag.block)
      end
    end

    ############### tags: tags for displaying assets when we have a tag
                  # similar tags already exist for pages

    desc %{
      Loops through the assets to which the present tag has been applied
    
      *Usage:* 
      <pre><code><r:tag:assets:each>...</r:tag:assets:each></code></pre>
    }    
    tag 'tag:assets' do |tag|
      raise TagError, "tag must be defined for tag:assets tag" unless tag.locals.tag
      tag.locals.assets = tag.locals.tag.assets
      tag.expand
    end
    tag 'tag:assets:each' do |tag|
      tag.render('assets:each', tag.attr.dup, &tag.block)
    end
  
    desc %{
      Renders the contained elements only if there are any assets associated with the current tag.

      *Usage:* 
      <pre><code><r:tag:if_assets>...</r:tag:if_assets></code></pre>
    }
    tag "tag:if_assets" do |tag|
      raise TagError, "tag must be defined for tag:if_assets tag" unless tag.locals.tag
      tag.locals.assets = tag.locals.tag.assets
      tag.expand if tag.locals.assets.any?
    end

    desc %{
      Renders the contained elements only if there are no assets associated with the current tag.

      *Usage:* 
      <pre><code><r:tag:unless_assets>...</r:tag:unless_assets></code></pre>
    }
    tag "tag:unless_assets" do |tag|
      raise TagError, "tag must be defined for tag:unless_assets tag" unless tag.locals.tag
      tag.locals.assets = tag.locals.tag.assets
      tag.expand unless tag.locals.assets.any?
    end
    
    ############### libraryish utility tags that don't really belong here
    # btw. the truncation tags are duplicated from the reader extension, which may
    # or may not be installed here. I'll move them into radiant proper in the end
    
    desc %{
      Truncates the contained text or html to the specified length. Unless you supply a 
      html="true" parameter, all html tags will be removed before truncation. You probably
      don't want to do that: open tags will not be closed and the truncated
      text length will vary.

      <pre><code>
        <r:truncated words="30"><r:content part="body" /></r:truncated>
        <r:truncated chars="100" omission=" (continued)"><r:post:body /></r:truncated>
        <r:truncated words="100" allow_html="true"><r:reader:description /></r:truncated>
      </code></pre>
    }
    tag "truncated" do |tag|
      content = tag.expand
      tag.attr['words'] ||= tag.attr['length']
      omission = tag.attr['omission'] || '&hellip;'
      content = scrub_html(content) unless tag.attr['allow_html'] == 'true'
      if tag.attr['chars']
        truncate(content, :length => tag.attr['chars'].to_i, :omission => omission)
      else
        truncate_words(content, :length => tag.attr['words'].to_i, :omission => omission)   # defined in TaggableHelper
      end
    end

    deprecated_tag "truncate", :substitute => "truncated"

    desc %{
      Strips all html tags from the contained text, leaving the text itself unchanged. 
      Useful when, for example, using a page part to populate a meta tag.
    }
    tag "strip" do |tag|
      # strip_html is in TaggableHelper
      scrub_html tag.expand
    end

    desc %{
      Removes all unsafe html tags and attributes from the enclosed text, protecting from cross-site scripting attacks while leaving the text intact.
    }
    tag "clean" do |tag|
      # clean_html is in TaggableHelper
      clean_html tag.expand
    end    

  private

    def _get_tag(tag, options)
      if title = options.delete('title')
        tag.locals.tag ||= Tag.find_by_title(title)
      elsif id = options.delete('id')
        tag.locals.tag ||= Tag.find_by_id(id)
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
        tag.locals.page.attached_tags.visible
      else
        []
      end
      tag.locals.tags = tags.uniq.compact
    end  

    def _asset_finder(tag)
      if (tag.locals.tags)
        Asset.from_all_tags(tag.locals.tags).not_furniture
      else
        Asset.not_furniture
      end
    end

  end
end