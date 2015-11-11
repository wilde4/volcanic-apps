class SetAllExistingCvSettingsToTimeBased < ActiveRecord::Migration
  def change
    CvSearchSettings.all.each do |cv|
      if cv.access_control_type.nil?
        cv.update_attributes(access_control_type: "time")
      end
    end
  end
end
