# Taggable

This is another way to apply tags to objects in your radiant site and retrieve objects by tag. If you're looking at this you will also want to look at [tags](http://github.com/jomz/radiant-tags-extension/tree) extension, which does a good job of tag-clouding and may be all you need, and at our [paperclipped_taggable](https://github.com/spanner/radiant-paperclipped_taggable-extension) which uses this functionality to make image galleries and may be a useful starting point for other extensions.

## Why?

This extension differs in a few ways that matter to me but may not to you:

* Tags are (going to be) hierarchical: you can tag something with /games/cards/poker and start to build a taxonomy (NB. for now I've cut this out to get the core functionality right)
* We replace the keywords mechanism on pages rather than adding another one.
* Anything can be tagged. By default we only do pages but other extensions can participate with a single line in a model class. See the [paperclipped_taggable](https://github.com/spanner/radiant-paperclipped_taggable-extension) extension for an example or just put `is_taggable` at the top of a model class and see what happens.
* There is (soon) a handy tag-completer on the edit-page page
* We don't use `has_many_polymorphs` (it burns!)
* Or any of the tagging libraries: it only takes a few named_scope calls
* We're not so focused on tag clouds - though you can still (soon) make them - but more on archival and linking functions like 'related pages' and 'more about' and all that
* it's multi-site compatible: if our fork is installed then you get site-scoped tags and taggings.

When you first install the extension you shouldn't see much difference: all we do out of the box is take over the keywords field in the page-edit view.

## Status 

This extension is new but the code is well broken-in and has been in production for a couple of years.

I'm finally getting round to packaging it up properly but I wouldn't say I'd quite finished that job yet! Lots of functionality has been removed from this version so that I can refactor it a bit. Some of that will appear in `paperclipped_taggable`, some in here, some in other extensions.

## Warnings

* No tests yet! Bad hurrying deadline code is likely.
* Some bits of this are quite old and still eg. using `make_resourceful`
* I've stripped out a lot of the interesting bits in order to see the shared is_taggable functionality working, so the next version will have a lot more bells and whistles

## Requirements

* Radiant 0.7.x.

## Installation

As usual:

	git submodule add git://github.com/spanner/radiant-taggable-extension.git vendor/extensions/taggable
	rake radiant:extensions:taggable:update
	
The update task can be omitted: it only brings over some CSS that might provide a useful starting point.

## Author and copyright

* William Ross, for spanner. will at spanner.org
* Copyright 2009 spanner ltd
* released under the same terms as Rails and/or Radiant