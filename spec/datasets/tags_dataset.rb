require 'digest/sha1'

class TagsDataset < Dataset::Base
  datasets = [:pages]
  datasets << :tag_sites if defined? Site
  uses *datasets
  
  def load
    create_tag "colourless"
    create_tag "green"
    create_tag "ideas"
    create_tag "sleep"
    create_tag "furiously"
    
    apply_tag :colourless, pages(:first)
    apply_tag :ideas, pages(:first), pages(:another), pages(:grandchild)
    apply_tag :sleep, pages(:first)
    apply_tag :furiously, pages(:first)
    
    create_page "library", :slug => "library", :class_name => 'LibraryPage', :body => 'Shhhhh.'
  end
  
  helpers do
    def create_tag(title, attributes={})
      attributes = tag_attributes(attributes.update(:title => title))
      tag = create_model Tag, title.symbolize, attributes
    end
    
    def tag_attributes(attributes={})
      title = attributes[:name] || "Tag"
      attributes = { 
        :title => title
      }.merge(attributes)
      attributes[:site] = sites(:test) if defined? Site
      attributes
    end
        
    def apply_tag(tag, *items)
      tag = tag.is_a?(Tag) ? tag : tags(tag)
      items.each { |i| i.attached_tags << tag }
    end
    
  end
 
end