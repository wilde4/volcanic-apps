class Inventory < ActiveRecord::Base

  validates :name, presence: true
  validates :price, presence: true

  belongs_to :inventory_object

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

  private

  def strftime_string
    "%d %B %Y"
  end


end
