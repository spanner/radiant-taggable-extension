require "text/metaphone"

class Tag < ActiveRecord::Base
  attr_accessor :cloud_band, :cloud_size
  
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :page
  has_many :taggings, :dependent => :destroy
  before_save :calculate_metaphone
  
  has_site if respond_to? :has_site

  # returns the subset of tags meant for public display and selection
  
  named_scope :visible, {
    :conditions => ['visible = 1']
  }

  # returns the set of hidden editorial tags used for linking and labelling but
  # not meant for public display.

  named_scope :hidden, {
    :conditions => ['visible = 0']
  }
  
  # returns the subset of structural tags (ie, those that are page links)
  
  named_scope :structural, {
    :conditions => ['page_id IS NOT NULL']
  }

  # returns the subset of tags without page links
  
  named_scope :descriptive, {
    :conditions => ['page_id IS NULL']
  }

  # this is useful when we need to go back and add popularity to an already defined list of tags
  
  named_scope :in_this_list, lambda { |tags|
    {
      :conditions => ["tags.id IN (#{tags.map{'?'}.join(',')})", *tags.map{|t| t.is_a?(Tag) ? t.id : t}]
    }
  }
  
  # this is normally used to exclude current tags from a cloud or list
  
  named_scope :except, lambda { |tags|
    if tags.any?
      { :conditions => ["tags.id NOT IN (#{tags.map{'?'}.join(',')})", *tags.map{|t| t.is_a?(Tag) ? t.id : t}] }
    end
  }
  
  # NB unused tags are omitted
  
  named_scope :with_count, {
    :select => "tags.*, count(tt.id) AS use_count", 
    :joins => "INNER JOIN taggings as tt ON tt.tag_id = tags.id", 
    :group => "tags.id",
    :order => 'title ASC'
  }
  
  named_scope :most_popular, lambda { |count|
    {
      :select => "tags.*, count(tt.id) AS use_count", 
      :joins => "INNER JOIN taggings as tt ON tt.tag_id = tags.id", 
      :group => "tags.id",
      :limit => count,
      :order => 'use_count DESC'
    }
  }
  
  # this takes a list and returns all the tags attached to any item in that list
  # NB. won't work with a heterogeneous group: all items must be of the same class
  
  named_scope :attached_to, lambda { |these|
    klass = these.first.is_a?(Page) ? Page : these.first.class
    {
      :joins => "INNER JOIN taggings as tt ON tt.tag_id = tags.id", 
      :conditions => ["tt.tagged_type = '#{klass}' and tt.tagged_id IN (#{these.map{'?'}.join(',')})", *these.map(&:id)],
    }
  }
  
  # this takes a class name and returns all the tags attached to any object of that class
  
  named_scope :attached_to_a, lambda { |klass|
    klass = klass.to_s.titleize
    {
      :joins => "INNER JOIN taggings as tt ON tt.tag_id = tags.id", 
      :conditions => "tt.tagged_type = '#{klass}'",
    }
  }

  # this should probably be sorted better but I want to keep it as quick an operation as possible
  # so only the one query is allowed
  
  named_scope :suggested_by, lambda { |term|
    metaphone = Text::Metaphone.metaphone(term)
    {
      :conditions => ["tags.title LIKE ? OR tags.metaphone LIKE ?", "%#{term}%", "&#{metaphone}%"]
    }
  }
  
  # returns all the tags that have been applied alongside any of these tags: that is, the
  # set of tags that if applied will reduce further a set of tagged objects.
  
  named_scope :coincident_with, lambda { |tags|
    tag_ids = tags.map(&:id).join(',')
    {
      :select => "your_tags.*, COUNT(your_tags.id) AS use_count",
      :joins => %{
        INNER JOIN taggings AS my_taggings ON my_taggings.tag_id = tags.id 
        INNER JOIN taggings AS your_taggings ON my_taggings.tagged_type = your_taggings.tagged_type AND my_taggings.tagged_id = your_taggings.tagged_id
        INNER JOIN tags AS your_tags ON your_taggings.tag_id = your_tags.id
      }, 
      :conditions => "tags.id IN (#{tag_ids}) AND NOT your_tags.id IN (#{tag_ids})",
      :group => "your_tags.id"
    }
  }
  
  def <=>(othertag)
    String.natcmp(self.title, othertag.title)   # natural sort method defined in lib/natcomp.rb
  end
  
  def to_s
    title
  end
  
  # returns true if this tag points to a page
  
  def structural
    !page_id.nil?
  end
  alias :structural? :structural
  
  # Standardises formatting of tag name in urls
  
  def clean_title
    Rack::Utils.escape(title)
  end
  
  # Returns a list of all the objects tagged with this tag. We can't do this in SQL because it's polymorphic (and has_many_polymorphs makes my skin itch)
  
  def tagged
    taggings.map {|t| t.tagged}
  end
  
  # Returns a list of all the pages tagged with this tag.
  
  def pages
    Page.from_tags([self])
  end
  
  # Returns a list of all the assets tagged with this tag.
  
  def assets
    Asset.from_tags([self])
  end
  
  # Returns a list of all the assets of a particular type tagged with this tag.
  
  Asset.known_types.each do |type|
    define_method type.to_s.pluralize.intern do
      Asset.send("#{type.to_s.pluralize}".intern).from_tags([self])
    end
  end
  
  # Returns a list of all the tags that have been applied alongside this one.
  
  def coincident_tags
    self.class.coincident_with(self)
  end
    
  # returns true if tags are site-scoped
  
  def self.sited?
    !reflect_on_association(:site).nil?
  end
  
  # turns an array or comma-separated string of tag titles into a list of tag objects, creating if specified

  def self.from_list(list=[], or_create=true)
    list = list.split(/[,;]\s*/) if String === list
    list.uniq.map {|t| self.for(t, or_create) }.select{|t| !t.nil? } if list && list.any?
  end
  
  def self.to_list(tags=[])
    tags.uniq.map(&:title).join(',')
  end
  
  # finds or creates a tag with the supplied title
  
  def self.for(title, or_create=true)
    if or_create
      self.sited? ? self.find_or_create_by_title_and_site_id(title, Page.current_site.id) : self.find_or_create_by_title(title)
    else
      self.sited? ? self.find_by_title_and_site_id(title, Page.current_site.id) : self.find_by_title(title)
    end
  end
  
  # applies the usual cloud-banding algorithm to a set of tags with use_count
  
  def self.banded(tags=Tag.most_popular(100), bands=6)
    if tags
      count = tags.map{|t| t.use_count.to_i}
      if count.any? # urgh. dodging named_scope count bug
        max_use = count.max
        min_use = count.min
        divisor = ((max_use - min_use) / bands) + 1
        tags.each do |tag|
          tag.cloud_band = (tag.use_count.to_i - min_use) / divisor
        end
        tags
      end
    end
  end
  
  # applies a more sophisticated logarithmic weighting algorithm to a set of tags.
  # derived from here:
  # http://stackoverflow.com/questions/604953/what-is-the-correct-algorthm-for-a-logarthmic-distribution-curve-between-two-poin
  
  def self.sized(tags=Tag.most_popular(100), threshold=0, biggest=1.0, smallest=0.4)
    if tags
      counts = tags.map{|t| t.use_count.to_i}
      if counts.any?
        max = counts.max
        min = counts.min
        if max == min
          tags.each do |tag|
            tag.cloud_size = sprintf("%.2f", biggest/2 + smallest/2)
          end
        else
          steepness = Math.log(max - (min-1))/(biggest - smallest)
          tags.each do |tag|
            offset = Math.log(tag.use_count.to_i - (min-1))/steepness
            tag.cloud_size = sprintf("%.2f", smallest + offset)
          end
        end
        tags
      end
    end
  end
  
  # takes a list of tags and reaquires it from the database, this time with incidence.
  # cheap call because it returns immediately if the list is already cloudable.
  
  def self.for_cloud(tags)
    return tags if tags.empty? || tags.first.cloud_size
    sized(in_this_list(tags).with_count)
  end
  
  def self.cloud_from(these)
    for_cloud(attached_to(these))
  end
  
  # adds retrieval methods for a taggable class to this class and to Tagging.
  
  def self.define_retrieval_methods(classname)
    define_method "#{classname.downcase}_taggings".to_sym do
      self.taggings.of_a(classname)
    end
    define_method classname.downcase.pluralize.to_sym do
      classname.constantize.send :from_tag, self
    end
  end  

protected
  
  def calculate_metaphone
    self.metaphone = Text::Metaphone.metaphone(self.title) if self.respond_to? :metaphone=
  end
end

