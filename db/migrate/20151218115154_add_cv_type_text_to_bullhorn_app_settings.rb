class AddCvTypeTextToBullhornAppSettings < ActiveRecord::Migration
  def change
    add_column :bullhorn_app_settings, :cv_type_text, :string
  end
end
