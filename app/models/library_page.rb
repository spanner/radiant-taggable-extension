class LibraryPage < Page
  include Taggable::FacetedPage
  description %{ Takes tag names in child position or as paramaters so that tagged items can be listed. }
end
