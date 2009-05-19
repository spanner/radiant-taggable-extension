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
    tags = tag.locals.page.tags.find(:all, _find_options(tag))
    tags.each do |item|
      tag.locals.tag = item
      result << tag.expand
    end 
    result
  end
    
  # related pages
  
  desc %{
    Cycles through related pages of either page or asset in descending order of relatedness
    
    *Usage:* 
    <pre><code><r:related_pages:each>...</r:related_pages:each></code></pre>
  }    
  tag 'related_pages' do |tag|
    raise TagError, "page or asset must be defined for related_pages tag" unless tag.locals.page or tag.locals.asset
    tag.expand
  end
  tag 'related_pages:each' do |tag|
    result = []
    thing = tag.locals.page || tag.locals.asset
    thing.related_pages.each do |page|
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
      tags ||= tag.locals.page.tags if tags.empty? && tag.locals.page
      tags ||= tag.locals.asset.tags if tags.empty? && tag.locals.asset
      raise TagError, "can't find any tags" if tags.empty?
      tags
    end

  
  
  
  
end