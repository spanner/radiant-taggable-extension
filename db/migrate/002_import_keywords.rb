class ImportKeywords < ActiveRecord::Migration
  def self.up
    Page.find(:all).each do |page|
      page.tags_from_keywords
    end
  end

  def self.down

  end
end
