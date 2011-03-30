module TaggableHelper

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
