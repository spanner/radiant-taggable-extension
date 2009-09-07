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

When you first install the extension you shouldn't see much difference: all we do out of the box is to take over (and make more prominent) the keywords field in the page-edit view.

## New

* faceted retrieval by combining tags.
* navigation submenu (requires submenu extension)

## Status 

New and still a bit of a moving target. The underlying code is fairly well broken-in and has been in production for a couple of years, but I've rearranged it quite drastically and the interface is all new.

There are tests now: not detailed but with reasonable coverage. Silly mistakes are getting less likely.

## Efficiency

Not too bad, I think. The tag pages are cached and most of the heavy retrieval functions have been squashed down into single queries. Each of these:

	Tag.most_popular(50)
	Tag.coincident_with(tag1, tag2, tag3)
	Page.tagged_with(tag1, tag2, tag3)
	Page.related_pages 								# equivalent to Page.tagged_with(self.attached_tags) - [self]

is handled in a single pass. 

The exception is the `r:tag_cloud` tag: there we have to gather a list of descendant pages first. It's done in a fairly frugal way (by generation rather than individual) but still likely to involve several preparatory queries as well as the cloud computation.

## Tag pages

The **TagPage** page type is just a handy way of catching tag parameters: any path following the address of the page is taken as a slash-separated list of tags, so with a tag page at /archive/tags you can call addresses like:

	/archive/tags/lasagne/chips/pudding
	
and the right tags will be retrieved, if they exist, and made available to the page, where you can display them using the luxurious assortment of tags below.

## Radius tags

This extension creates a lot of radius tags. There are three kinds:

### radius tags for use with single tags

are used in the usual to display the properties and associations of a given tag (which can be supplied to a tag page as a query parameter or just specified in the radius tag)

	<r:tag:title />
	<r:tag:description />
	<r:tag:pages:each>...</r:tag:pages:each>

currently only available in a tag cloud (or a `top_tags` list):

	<r:tag:use_count />
	<r:tag:cloud_band />

### radius tags for use on normal pages

These display the tag-associations of a given page.

	<r:if_tags>...</r:if_tags>
	<r:unless_tags>...</r:unless_tags>
	<r:tags:each>...</r:tags:each>
	<r:related_pages:each>...</r:related_pages:each>
	<r:tag_cloud [url=""] />
	
You can also use the TagPage display functions with the prefix `page_tags`:

	<r:page_tags:summary />

which isn't that useful out of the box but does give you some useful possibilities if `paperclipped_taggable` is installed. 

To illustrate a page automatically with all the images that share its tags:

	<r:page_tags:images:each><r:assets:image size="thumbnail" /></r:page_tags:images:each>
	
or to add a list of pdf downloads that match the page tags:

	<r:page_tags:pdfs:each><li><r:assets:link /></li></r:page_tags:pdfs:each>

### radius tags for use with sets of tags

These always have two parts: the first part chooses a set of tags and the second part dictates what to do with it.

These sets only work on TagPages

* **requested_tags** is the list of tags found in the request url
* **coincident_tags** is the list of tags that occur alongside all of the requested tags and can therefore be used to to narrow the result set further

and these three sets are also useable on normal pages:

* **all_tags** is just a list of all the available tags
* **top_tags** is a list of the most popular tags, with incidence and cloud bands
* **page_tags** is the list of tags attached to the present page

Each of these has a conditional version:

* eg **if_requested_tags** expands only if there are any tags requested

To each you can append conditions:

* **if_pages** expands if we can find any pages tagged with all of these tags
* **unless_pages** is the reverse.
	
	<r:requested_tags:if_pages>Yes, we have pages matching those tags.</r:requested_tags:if_pages>

or display instructions:

* **...:each** will loop through the set in the usual way
* **...:summary** will give a sentence summarising the set
* **...:list** will show an unordered list of tag links
* **...:cloud** will show a tag cloud with banding based on global tag application

	<r:all_tags:list />
	<r:requested_tags:summary />
	<r:coincident_tags:cloud />
	<r:top_tags:list limit="10" />

or lists of associated items:

* **...:pages:each** loops through the set of tagged pages
* **...:if_pages** expands if there are any tagged pages 
* **...:unless_pages** expands if there are none

eg.

	<r:requested_tags:pages:each>...</r:requested_tags:pages:each>

within that you can use all the usual page tags, and also:

	<r:crumbed_link />
	
which I find useful where page names are ambiguous.

There is also a useful shortcut for use on TagPages:

* **tag_chooser** displays a handy form 
	
The form lists and links correctly all the tags you might want to add to or remove from the present query. It gives a nice faceted search and at some point I'm going to combine it with a free-text index.

If you install the `paperclipped_taggable` extension then the set of tag-list options gets much larger:

	<r:requested_tags:images:each>...</r:requested_tags:images:each>
	<r:requested_tags:non_images:each>...</r:requested_tags:non_images:each>
	<r:requested_tags:if_videos>...</r:requested_tags:if_videos>
	<r:requested_tags:unless_non_images>...</r:requested_tags:unless_non_images>
	...etc
	
## Note about tag cloud banding

There are two ways in which you might want to use a tag cloud. It can be used as an illustration, to characterise a list or section of the site, or it can be used as a control element, for choosing tags. The display logic is slightly different in each case:

### descriptive tag clouds

If you put

	<r:tag_cloud />
	
on a page, the cloud will show all the tags that are attached to that page and its descendants. The idea is to show what's going on locally, and prominence in the cloud will come from the importance of the tag _within this set_. If all the pages in this section are tagged with 'pie', then pie will be very prominent in the cloud.

### selective tag clouds

If you put

	<r:coincident_tags:cloud />
	
on a TagPage, then you will see a cloud of the tags that have been applied to the items in the current result set. In other words, all the tags that coincide with the requested tags. Here we want to show what's important globally, so prominence within the cloud is based on the total number of tag applications, not the number of applications within the present result set. 

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

### To create a destination page for tag links:

Create a page at (say) /archive/tags. Give it the TagPage type and this body:

	<h1>Tag: <r:tag:name /></h1>
	<p><r:tag:description /></p>
	<ul>
	  <r:tag:pages:each>
	    <li><r:crumbed_link /></li>
	  </r:tag:pages:each>
	</ul>

### To display a tag cloud on a section front page:

Include the sample tagcloud.css in your styles and put this somewhere in the page or layout:

	<r:tag_cloud />

Seek venture capital immediately.

### To turn your destination page into a faceted library page

Take the single-tag stuff out of your TagPage and replace it with:

	<r:tag_chooser />

	<r:requested_tags:if_pages>
	  <h2>Pages tagged with <r:requested_tags:summary /></h2>
	  <ul>
      <r:requested_tags:pages:each>
        <li><r:crumbed_link omit_root="true" /></li>
      </r:requested_tags:pages:each>
	  </ul>
	</r:requested_tags:if_pages>

	<r:requested_tags:unless_pages>
	  <p>No pages have been tagged with <r:requested_tags:summary /></p>
	</r:requested_tags:unless_pages>
	
## Next steps

* auto-completer to improve tagging consistency.
	
## Requirements

* Radiant 0.8.0

This is not any longer compatible with 0.7 because we're doing a lot of :having in the scopes and you need rails 2.3 for that.

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