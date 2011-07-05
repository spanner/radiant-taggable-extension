module TaggableHelper

  def clean_html(text)
    Sanitize.clean(text, Sanitize::Config::RELAXED)
  end

  def strip_html(text)
    Sanitize.clean(text)
  end

  def truncate_words(text='', options={})
    return '' if text.blank?
    ellipsis = options[:ellipsis] || '&hellip;'
    limit = (options[:limit] || 64).to_i
    text = strip_html(text) if options[:strip]
    words = text.split
    ellipsis = '' unless words.size > limit
    words[0..(limit-1)].join(" ") + ellipsis
  end 

  def available_pointer_pages()
    root = Page.respond_to?(:homepage) ? Page.homepage : Page.find_by_parent_id(nil)
    options = pointer_option_branch(root)
    options.unshift ['<none>', nil]
    options
  end
    
  def pointer_option_branch(page, depth=0)
    options = []
    unless page.virtual? || page.sheet? || page.has_pointer?
      options << ["#{". " * depth}#{h(page.title)}", page.id]
      page.children.each do |child|
        options += pointer_option_branch(child, depth + 1)
      end
    end
    options
  end

end
