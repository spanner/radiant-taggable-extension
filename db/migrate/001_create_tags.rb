class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.column :title,            :string
      t.column :description,      :text
      t.column :created_by_id,    :integer
      t.column :updated_by_id,    :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :site_id,         :integer
    end
    add_index :tags, :title, :unique => true

    create_table :taggings do |t|
      t.column :tag_id,           :integer
      t.column :tagged_type,      :string
      t.column :tagged_id,        :integer
    end
    add_index :taggings, [:tag_id, :tagged_id, :tagged_type], :unique => true
  end

  def self.down
    drop_table :tags
    drop_table :taggings
  end
end
