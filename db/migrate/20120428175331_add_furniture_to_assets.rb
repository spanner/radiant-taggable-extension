class AddFurnitureToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :furniture, :boolean, :default => false
  end

  def self.down
    remove_column :assets, :furniture
  end
end
