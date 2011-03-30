class StructuralTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :page_id, :integer
    add_column :tags, :visible, :boolean, :default => true
    
    Tag.reset_column_information
    Tag.all.each do |tag|
      tag.visible = true
      tag.save
    end
  end

  def self.down
    remove_column :tags, :page_id
    remove_column :tags, :visible
  end
end
