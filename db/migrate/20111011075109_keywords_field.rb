class KeywordsField < ActiveRecord::Migration
  def self.up
    Page.find(:all).each do |page|
      if keywords = page.field(:keywords).try(:content)
        page.attached_tags = Tag.from_list(keywords)
        page.save
      end
      page.field(:keywords).delete
    end
  end

  def self.down

  end
end
