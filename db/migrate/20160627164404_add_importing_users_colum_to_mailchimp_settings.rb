class AddImportingUsersColumToMailchimpSettings < ActiveRecord::Migration
  def change
    add_column :mail_chimp_app_settings, :importing_users, :boolean
  end
end
