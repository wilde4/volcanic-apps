class RegistrationBonus < ActiveRecord::Base

  has_many :inventory_registration_bonuses
  has_many :inventories, through: :inventory_registration_bonuses


end