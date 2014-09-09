class CreateAchievements < ActiveRecord::Migration
  def change
    create_table :achievements do |t|
      t.integer :user_id
      t.boolean :signed_up, default: false
      t.boolean :downloaded_app, default: false
      t.boolean :uploaded_cv, default: false
      t.boolean :liked_job, default: false
      t.boolean :shared_social, default: false
      t.boolean :completed_profile, default: false
      t.string  :level
    end
  end
end
