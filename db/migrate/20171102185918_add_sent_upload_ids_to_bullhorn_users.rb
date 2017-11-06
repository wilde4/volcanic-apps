class AddSentUploadIdsToBullhornUsers < ActiveRecord::Migration
  def change
    add_column :bullhorn_users, :sent_upload_ids, :string
  end
end
