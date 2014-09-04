class Inventory < ActiveRecord::Base

  validates :name, presence: true
  validates :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :inventory_object_id, presence: true

  scope :by_dataset, -> id { where(dataset_id: id) }
  scope :by_object, -> id { where(inventory_object_id: id) }

  # Calls strftime on start_date and returns a human-friendly version
  def human_start_date
    self.start_date.strftime(strftime_string)
  end

  def human_end_date
    self.end_date.strftime(strftime_string)
  end

  def within_date
    active_start = start_date.nil? || start_date <= Date.today
    active_end = end_date.nil? || end_date >= Date.today
    active_start && active_end
  end
  
  def self.object_name(id)
    self.inventory_objects.each do |obj|
      return obj[:name] if obj[:id] == id
    end
    nil
  end

  def self.object_by_name(name)
    self.inventory_objects.each do |obj|
      return obj if obj[:name] == name
    end
    nil
  end

  def self.inventory_objects
    [
      {id: 1, name: 'Credit', attribute: '' },
    ]
  end

private
  def strftime_string
    "%d %B %Y"
  end


end
