class AddLastPetitionAtColumnToSemrushAppSettings < ActiveRecord::Migration
  def change
    add_column :semrush_app_settings, :last_petition_at, :date
  end
end
