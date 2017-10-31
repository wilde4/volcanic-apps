class AddSendCoverLetterToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :send_cover_letter, :boolean, default: false
  end
end
