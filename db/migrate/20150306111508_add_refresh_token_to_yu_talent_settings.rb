class AddRefreshTokenToYuTalentSettings < ActiveRecord::Migration
  def change
    add_column :yu_talent_settings, :refresh_token, :string
  end
end
