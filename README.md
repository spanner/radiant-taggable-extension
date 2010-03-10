# Taggable

This is another way to apply tags to objects in your radiant site and retrieve objects by tag. If you're looking at this you will also want to look at the [tags](http://github.com/jomz/radiant-tags-extension/tree) extension, which does a good job of tag-clouding and may be all you need, and at our [library](https://github.com/spanner/radiant-library-extension) which uses this functionality to make an image gallery and document library and may be a useful starting point for other extensions.

## Why?

This extension differs from `tags` in a few ways that matter to me but may not to you:

* We're not so focused on tag clouds - though you can still make them - but more on archival and linking functions.
* We replace the keywords mechanism on pages rather than adding another one.
* Anything can be tagged. By default we only do pages but other extensions can participate with a single line in a model class. See the [taggable_events](https://github.com/spanner/radiant-taggable_events-extension) extension for a minimal example or just put `is_taggable` at the top of a model class and see what happens.
* We don't use `has_many_polymorphs` (it burns!)
* Or any of the tagging libraries: it only takes a few named_scopes
* it's multi-site compatible: if our fork is installed then you get site-scoped tags and taggings.

When you first install the extension you shouldn't see much difference: all we do out of the box is to take over (and make more prominent) the keywords field in the page-edit view.

## New

I've just stripped out quite a lot of display clutter in order to focus on the basic tagging mechanism here. Retrieval and display is now handled by the [library](http://example.com/) extension. The core radius tags remain here. Anything that used to refer to a tag page is probably now handled by the library page.

## Status 

The underlying code is fairly well broken-in and has been in production for a couple of years, but I've rearranged it quite drastically and the interface is all new. There are tests now: not detailed but with reasonable coverage. Silly mistakes are getting less likely.

## Efficiency

Not too bad, I think. Most of the heavy retrieval functions have been squashed down into single queries. Each of these:

	Tag.most_popular(50)
	Tag.coincident_with(tag1, tag2, tag3)
	Page.tagged_with(tag1, tag2, tag3)
	Page.related_pages 								# equivalent to Page.tagged_with(self.attached_tags) - [self]

is handled in a single pass. 

The exception is the `r:tag_cloud` tag: there we have to gather a list of descendant pages first. It's done in a fairly frugal way (by generation rather than individual) but still likely to involve several preparatory queries as well as the cloud computation.

## Radius tags

This extension creates several radius tags. There are two kinds:

### presenting tag information

are used in the usual to display the properties and associations of a given tag (which can be supplied to a library as a query parameter or just specified in the radius tag)

	<r:tag:title />
	<r:tag:description />
	<r:tag:pages:each>...</r:tag:pages:each>

currently only available in a tag cloud (or a `top_tags` list):

	<r:tag:use_count />

### presenting page information

These display the tag-associations of a given page.

	<r:if_tags>...</r:if_tags>
	<r:unless_tags>...</r:unless_tags>
	<r:tags:each>...</r:tags:each>
	<r:related_pages:each>...</r:related_pages:each>
	<r:tag_cloud [url=""] />

The library extension adds a lot more ways to retrieve lists of tags and tagged objects, and to work with assets in the same way as we do here with pages.
	
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
	    <r:related_pages.each>
	  </ul>
	</r:if_tags>

### To display a tag cloud on a section front page:

Include the sample tagcloud.css in your styles and put this somewhere in the page or layout:

	<r:tag_cloud />

Seek venture capital immediately.
	
## Next steps

* auto-completer to improve tagging consistency.
	
## Requirements

* Radiant 0.8.1
* `will_paginate` gem

This is no longer compatible with 0.7 because we're doing a lot of :having in the scopes and you need rails 2.3 for that.

## Installation

As usual:

	git clone git://github.com/spanner/radiant-taggable-extension.git vendor/extensions/taggable
	rake radiant:extensions:taggable:migrate
	rake radiant:extensions:taggable:update

The update task will bring over a couple of CSS files for styling tags but you'll want to improve those.

## Bugs

Very likely. [Github issues](http://github.com/spanner/radiant-taggable-extension/issues), please, or for little things an email or github message is fine.

## Author and copyright

* William Ross, for spanner. will at spanner.org
* Copyright 2009 spanner ltd
* released under the same terms as Rails and/or Radiant