# Taggable

This is another way to apply tags to objects in your radiant site and retrieve objects by tag. If you're looking at this you will also want to look at the [tags](http://github.com/jomz/radiant-tags-extension/tree) extension, which does a good job of tag-clouding and may be all you need, and at our [paperclipped_taggable](https://github.com/spanner/radiant-paperclipped_taggable-extension) which uses this functionality to make image galleries and may be a useful starting point for other extensions.

## Why?

This extension differs in a few ways that matter to me but may not to you:

* We're not so focused on tag clouds - though you can still make them - but more on archival and linking functions.
* We replace the keywords mechanism on pages rather than adding another one.
* Anything can be tagged. By default we only do pages but other extensions can participate with a single line in a model class. See the [paperclipped_taggable](https://github.com/spanner/radiant-paperclipped_taggable-extension) extension for an example or just put `is_taggable` at the top of a model class and see what happens.
* There is (soon) a handy tag-completer on the edit-page page
* We don't use `has_many_polymorphs` (it burns!)
* Or any of the tagging libraries: it only takes a few named_scope calls
* it's multi-site compatible: if our fork is installed then you get site-scoped tags and taggings.

When you first install the extension you shouldn't see much difference: all we do out of the box is take over (and make more prominent) the keywords field in the page-edit view.

## Status 

New and still a bit of a moving target. The underlying code is fairly well broken-in and has been in production for a couple of years, but I've rearranged it quite drastically and the interface stuff is all new. Right now I'm busy working on the retrieval functions: getting back all the pages, images and other assets for a supplied set of tags. There will follow a set of examples that should make all this a lot more useable.

There are basic tests now: not detailed but with reasonable coverage. Silly mistakes are getting less likely.

## Tag pages

The **TagPage** page type is just a handy way of catching tag parameters: any path following the address of the page is taken as a slash-separated list of tags, so with a TagPage at /archive/tags you can call addresses like:

	/archive/tags/lasagne/chips/pudding
	
and the right tags will be retrieved, if they exist, and made available to the page, where you can display them using this luxurious assortment of tags:

## Radius tags

See the tag documentation for details, or have a look at the two example pages.

	<r:if_tags>...</r:if_tags>
	<r:unless_tags>...</r:unless_tags>
	<r:tags:each>...</r:tags:each>
	<r:tag_cloud [url=""] />
	<r:tag_cloud all="true" />
	
	<r:tag:title />
	<r:tag:description />
	<r:tag:pages:each>...</r:tag:pages:each>
	<r:related_pages:each>...</r:related_pages:each>

currently only populated in a tag cloud:

	<r:tag:use_count />
	<r:tag:cloud_band />

and only useful on a TagPage:

	<r:tagged_pages:if_any>...</r:tagged_pages:if_any>
	<r:tagged_pages:unless_any>...</r:tagged_pages:unless_any>
	<r:tagged_pages:each>...</r:tagged_pages:each>

after which you can use all the usual page tags, and also:

	<r:crumbed_link />
	
which I find useful where page names are ambiguous.

## Usage

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

### To create a destination page for tag links:

Create a page at (say) /archive/tags. Give it the TagPage type and this body:

	<h1>Tag: <r:tag:name /></h1>
	<p><r:tag:description /></p>
	<ul>
	  <r:tag:pages:each>
	    <li><r:crumbed_link /></li>
	  </r:tag:pages:each>
	</ul>

### To display a tag cloud:

Include the sample tagcloud.css in your styles and put this somewhere on a page:

	<r:tag_cloud />

By default it will show tags for the current page and its descendants, so you may want to tell it to show the whole site:

	<r:tag_cloud url="/" destination="/archive/tags" />

Seek venture capital immediately.

## Next steps

* sensible display of items associated with sets of tags (for what is essentially a faceted search)
* auto-completer to improve tagging consistency.
	
## Requirements

* Radiant 0.7.x or 0.8.0

## Installation

As usual:

	git clone git://github.com/spanner/radiant-taggable-extension.git vendor/extensions/taggable
	rake radiant:extensions:taggable:migrate
	rake radiant:extensions:taggable:update

The update task will bring over a couple of CSS files for styling tags but you'll want to improve those.
	
## Author and copyright

* William Ross, for spanner. will at spanner.org
* Copyright 2009 spanner ltd
* released under the same terms as Rails and/or Radiant