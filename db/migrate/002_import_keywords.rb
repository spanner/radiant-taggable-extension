class ImportKeywords < ActiveRecord::Migration
  def self.up
    Page.find(:all).each do |page|
      page.keywords = page.read_attribute(:keywords)
    end
  end

  def self.down

  end
end
