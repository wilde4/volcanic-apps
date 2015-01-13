class AddLinkedInToBullhornUsers < ActiveRecord::Migration
  def change
    add_column :bullhorn_users, :linkedin_profile, :text
  end
end
