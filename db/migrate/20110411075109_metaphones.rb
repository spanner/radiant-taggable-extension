class Metaphones < ActiveRecord::Migration
  def self.up
    add_column :tags, :metaphone, :string
    add_column :tags, :metaphone_secondary, :string
    Tag.reset_column_information
    Tag.all.each do |tag|
      tag.send :save    # metaphone is calculated before_save
    end
  end

  def self.down
    remove_column :tags, :metaphone
    remove_column :tags, :metaphone_secondary
  end
end
