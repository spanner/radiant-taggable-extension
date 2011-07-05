module Radius
  module AssetTags
    include Radiant::Taggable
  
    class TagError < StandardError; end

    %w{tags tags:each copyright if_copyright unless_copyright minigallery illustration}.each do |name|
      deprecated_tag "assets:#{name}", :substitute => "asset:#{name}", :deadline => '2.0'
    end


    ############### assets: tags for displaying tags and relatives when we have an asset
                  # similar tags already exist for pages
  
    desc %{
      Cycles through all tags attached to present asset.
    
      *Usage:* 
      <pre><code><r:assets:tags><r:tag:title /></r:assets:tags></code></pre>
    }    
    tag 'asset:tags' do |tag|
      raise TagError, "asset must be defined for asset:tags tag" unless tag.locals.asset
      tag.locals.tags = tag.locals.asset.tags
      tag.expand
    end
    tag 'asset:tags:each' do |tag|
      tag.render('tags:each', tag.attr.dup, &tag.block)
    end

    desc %{
      Lists all the assets similar to this asset (based on its tagging), in descending order of relatedness.
    
      *Usage:* 
      <pre><code><r:related_assets:each>...</r:related_assets:each></code></pre>
    }
    tag 'related_assets' do |tag|
      raise TagError, "asset must be defined for related_assets tag" unless tag.locals.asset
      tag.locals.assets = tag.locals.asset.related_assets
      tag.expand
    end
    tag 'related_assets:each' do |tag|
      tag.render('assets:each', tag.attr.dup, &tag.block)
    end

    ############### extra asset fields

    desc %{
      Expands if the asset has a copyright notice.
    }
    tag "asset:if_copyright" do |tag|
      options = tag.attr.dup
      asset = find_asset(tag, options)
      tag.expand if asset.respond_to?(method) && asset.send(method)
    end
    
    desc %{
      Expands unless the asset has a copyright notice.
    }
    tag "asset:unless_copyright" do |tag|
      options = tag.attr.dup
      asset = find_asset(tag, options)
      tag.expand unless asset.respond_to?(method) && asset.send(method)
    end

    desc %{
      Renders the 'copyright' attribute of the asset.
    }
    tag "asset:copyright" do |tag|
      options = tag.attr.dup
      asset = find_asset(tag, options)
      asset.send(method) rescue nil
    end

    ############### useful shorthands

    desc %{
      Renders an illustration block for the asset, with image and caption.

      *Usage:* 
      <pre><code><r:assets:image [title="asset_title"] [size="icon|thumbnail"]></code></pre>
    }    
    tag "asset:illustration" do |tag|
      options = tag.attr.dup
      options['size'] ||= 'illustration'
      tag.locals.asset = find_asset(tag, options)
      if tag.locals.asset.image?
        result = %{<div class="illustration">}
        result << tag.render('assets:image', options)
        result << %{<p class="caption">#{tag.render('assets:caption', options)}</p>}
        result << "</div>"
        result
      end
    end
    
    desc %{ 
      Presents a standard marginal gallery block suitable for turning unobtrusively into a rollover or lightbox gallery. 
      We need to be able to work out a collection of assets: that can be defined already (eg by assets:all) or come from the current page.
      Default preview size is 'large' and thumbnail size 'thumbnail' but you can specify any of your asset sizes.

      *Usage:*
      <pre><code>
        <r:assets:images>
          <r:assets:minigallery [size="..."] [thumbnail_size="..."] [tags="one,or,more,tags"] />
        </r:assets:images>
      </code></pre>

    }
    tag 'asset:minigallery' do |tag|
      options = tag.attr.dup.symbolize_keys
      raise TagError, "asset collection must be available for assets:minigallery tag" unless tag.locals.assets or tag.locals.page or tag.attr[:tags]
      if options[:tags] && tags = Tag.from_list(options[:tags])
        tag.locals.assets = Asset.images.from_all_tags(tags)
      else
        tag.locals.assets = tag.locals.page.assets
      end
      tag.locals.assets.images.to_a     # because we can't let empty? trigger a call to count

      unless tag.locals.assets.empty?
        size = tag.attr['size'] || 'illustration'
        thumbsize = tag.attr['thumbnail_size'] || 'icon'
        result = ""
        result << %{
  <div class="minigallery">}
        tag.locals.asset = tag.locals.assets.first
        result << tag.render('assets:image', {'size' => size})
        result << %{
    <p class="caption">#{tag.render('assets:caption')}</p>
    <ul class="thumbnails">}
        if tag.locals.assets.size > 1
          tag.locals.assets.each do |asset|
            tag.locals.asset = asset
            result << %{
      <li class="thumbnail">
        <a href="#{tag.render('assets:url', 'size' => 'illustration')}" title="#{asset.caption}" id="thumbnail_#{asset.id}">
          }
            result << tag.render('assets:image', {'size' => thumbsize, 'alt' => asset.title})
            result << %{
        </a>
      </li>}
          end
        end
        result << %{
    </ul>
  </div>}
        result
      end
    end

  end
end

