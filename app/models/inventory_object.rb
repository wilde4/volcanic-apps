class InventoryObject < ActiveRecord::Base
  has_many :inventories
end