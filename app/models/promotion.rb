class Promotion < ActiveRecord::Base
  belongs_to :role

  # Calls strftime on start_date and returns a human-friendly version
  def human_start_date
    self.start_date.strftime(strftime_string)
  end

  def human_end_date
    self.end_date.strftime(strftime_string)
  end

  private

  def strftime_string
    "%d %b %Y, %H:%M"
  end


end
