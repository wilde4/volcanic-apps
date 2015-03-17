class AddAccessTokenToEventbriteSettings < ActiveRecord::Migration
  def change
    add_column :eventbrite_settings, :access_token, :string
  end
end
