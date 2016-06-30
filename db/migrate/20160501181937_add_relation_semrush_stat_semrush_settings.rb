class AddRelationSemrushStatSemrushSettings < ActiveRecord::Migration
  def change
    add_reference :semrush_stats, :semrush_app_settings, index: true
  end
end
