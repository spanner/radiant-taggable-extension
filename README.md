# Taggable

This is another way to apply tags to objects in your radiant site and retrieve objects by tag. If you're looking at this you will also want to look at the [tags](http://github.com/jomz/radiant-tags-extension/tree) extension, which does a good job of tag-clouding and may be all you need.

Taggable now includes what was previously the `library` extension so it handles radiant assets as well as pages and provides radius tags to support a faceted search.

## Why?

This extension differs from `tags` in a few ways that matter to me but may not to you:

* We're not so focused on tag clouds - though you can still make them - but more on archival and linking functions.
* It provides faceted search of any tagged class.
* We subvert the keywords mechanism on pages rather than adding another one. I may change this soon to play more nicely with page fields.
* The tag-choosing and tag-removal interface is (about to be) quite nice.
* It's editorially versatile: tags can be used as page pointers and their visibility is controllable
* Anything can be tagged. By default we only do pages but other extensions can participate with a single line in a model class. See the [taggable_events](https://github.com/spanner/radiant-taggable_events-extension) extension for a minimal example or just put `has_tags` at the top of a model class.
* We don't use `has_many_polymorphs` (it burns!)
* Or any of the tagging libraries: it only takes a few scopes

When you first install the extension you shouldn't see much difference: all we do out of the box is to take over (and make more prominent) the keywords field in the page-edit view.

## New

* API change: `has_tags` instead of `is_taggable`.

* The library extension has been reincorporated into taggable, since radiant 1 has assets. Out of the box you get tags, clouds and faceting of both pages and assets. It should work with 0.9.1 too but you will need paperclipped.

* The long-promised tag-suggester is there in a useable though slightly basic form.

## Status 

Apart from any crumpling caused by the recent reincorporation of Library this is all mature code that has been in use for years.

## Efficiency

Not too bad, I think. Most of the heavy retrieval functions have been squashed down into single queries. Each of these:

    Tag.most_popular(50)
    Tag.coincident_with(tag1, tag2, tag3)
    Page.tagged_with(tag1, tag2, tag3)
    Page.related_pages                              # equivalent to Page.tagged_with(self.attached_tags) - [self]
	Tag.suggested_by('stem')

is handled in a single pass. 

The exception is the `r:tag_cloud` tag: there we have to gather a list of descendant pages first. It's done in a fairly frugal way (by generation rather than individual) but still likely to involve several preparatory queries as well as the cloud computation.

## Library pages

The **LibraryPage** page type is a handy cache-friendly way of catching tag parameters and displaying lists of related items: any path following the address of the page is taken as a slash-separated list of tags, so with a tag page at /archive you can call addresses like:

    /archive/lasagne/chips/pudding
    
and the right tags will be retrieved, if they exist.

## Radius tags

This extension creates a great many radius tags. There are several kinds:

### Tag information

are used in the usual to display the properties and associations of a given tag (which can be supplied to a library as a query parameter or just specified in the radius tag)

    <r:tag:title />
    <r:tag:description />
    <r:tag:pages:each>...</r:tag:pages:each>
	<r:tags:each >...</r:tags:each>

currently only available in a tag cloud (or a `top_tags` list):

    <r:tag:use_count />

### Page tags and tag pages

These display the tag-associations of a given page.

    <r:if_tags>...</r:if_tags>
    <r:unless_tags>...</r:unless_tags>
    <r:tags:each>...</r:tags:each>
    <r:related_pages:each>...</r:related_pages:each>
    <r:tag_cloud [url=""] />

The library extension adds a lot more ways to retrieve lists of tags and tagged objects, and to work with assets in the same way as we do here with pages.

### Tag assets and asset tags

All the page tags have asset equivalents:

    <r:tags:assets:each tags="foo, bar">...</r:tags:assets:each>
    <r:related_assets:each>...</r:related_assets:each>

and for any `*asset*` tag you can substitute an asset type, so this also works:

    <r:related_images:each>...</r:related_images:each>

Within the each loops you can use all the usual page and asset tags.

### Library page tags

The library tags focus on two tasks: choosing a set of tags and displaying a set of matching objects.

    <r:library:tags />
    <r:library:tags:each>...</r:library:tags:each>
    
Displays a list of the tags available. If any tags have been requested, this will show the list of coincident tags (that can be used to limit the result set further). If not it shows all the available tags. If a `for` attribute is set:

    <r:library:tags for="images" />
    <r:library:tags for="pages" />

Then we show only the set of tags attached to any object of that kind.

    <r:library:requested_tags />
    <r:library:requested_tags:each>...</r:library:requested_tags:each>
    
Displays the currently-limiting set of tags.

    <r:library:pages:each>...</r:library:pages:each>
    <r:library:assets:each>...</r:library:assets:each>
    <r:library:images:each>...</r:library:images:each>
    <r:library:videos:each>...</r:library:videos:each>

Display the list of (that kind of) objects associated with the current tag set.

## Note about tag cloud prominence

The calculation of prominence here applies a logarithmic curve to create a more even distribution of weight. It's continuous rather than banded, and sets the font size and opacity for each tag in a style attribute.

## Usage examples

Add tags to your pages by putting a comma-separated list in the 'keywords' box. That's about to get more helpful.

### To show related pages:

Put this in your layout:

    <r:if_tags>
      <h3>See also</h3>
      <ul>
        <r:related_pages.each>
          <li><r:link /></li>
        </r:related_pages.each>
      </ul>
    </r:if_tags>

### To display a tag cloud on a section front page:

Include the sample tagcloud.css in your styles and put this somewhere in the page or layout:

    <r:tag_cloud />

Seek venture capital immediately.

### To display a faceted image browser on a library page:

    <r:library:if_requested_tags>
      <p>Displaying pictures tagged with <r:library:requested_tags /></p>
    </r:library:if_requested_tags>
    
    <r:library:images:each paginated="true" per_page="20">
      <r:assets:link size="full"><r:assets:image size="small" /></r:assets:link>
    </r:library:images:each>

    <r:library:tags for="images" />
    
### To automate the illustration of a page based on tag-overlap:

    <r:related_images:each limit="3">
      <r:assets:image size="standard" />
      <p class="caption"><r:assets:caption /></p>
    </r:related_images:each>
    
## Requirements

* Radiant 1 or radiant 0.9.x with the paperclipped extension. 

Radiant 1 is strongly recommended.

## Installation

As usual:

    git clone git://github.com/spanner/radiant-taggable-extension.git vendor/extensions/taggable
    rake radiant:extensions:taggable:migrate
    rake radiant:extensions:taggable:update

The update task will bring over a couple of CSS files for styling tags but you'll want to improve those.

## Bugs

Quite likely. [Github issues](http://github.com/spanner/radiant-taggable-extension/issues), please, or for little things an email or github message is fine.

## Author and copyright

* William Ross, for spanner. will at spanner.org
* Copyright 2008-2011 spanner ltd
* released under the same terms as Rails and/or Radiant