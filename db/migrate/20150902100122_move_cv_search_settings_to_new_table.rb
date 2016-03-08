class MoveCvSearchSettingsToNewTable < ActiveRecord::Migration
  def change
    JobBoard.all.each do |jb|
      jb.cv_search_settings = CvSearchSettings.new
      jb.cv_search_settings.charge_for_cv_search    = jb.charge_for_cv_search
      jb.cv_search_settings.require_access_for_cv_search = jb.require_access_for_cv_search
      jb.cv_search_settings.cv_search_price         = jb.cv_search_price
      jb.cv_search_settings.cv_search_title         = jb.cv_search_title
      jb.cv_search_settings.cv_search_description   = jb.cv_search_description
      jb.cv_search_settings.cv_search_duration      = jb.cv_search_duration
      jb.save
    end
  end
end
