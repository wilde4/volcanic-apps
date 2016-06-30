class ExtendLimitSemrushStatResults < ActiveRecord::Migration
  def change
    change_column :semrush_stats, :results, :bigint
  end
end
