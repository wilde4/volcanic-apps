class SemrushController < ApplicationController
  protect_from_forgery with: :null_session, except: [:save_settings]
  respond_to :json
  before_filter :set_key, only: [:index]
  after_filter :setup_access_control_origin
  
  def index
    @semrush_setting = SemrushAppSettings.find_by(dataset_id: params[:data][:dataset_id]) || SemrushAppSettings.new(dataset_id: params[:data][:dataset_id])
    
    @semrush_data = SemrushStat.where(engine: 'us', day: @semrush_setting.last_petition_at, dataset_id: params[:data][:dataset_id]).order('volume desc')
    @range_1 = @semrush_data.where('position >= 1 AND position <= 3').order('position asc')
    @range_1_keywords = @range_1.map(&:keyword)

    
    @range_2 = @semrush_data.where('position >= 4 AND position <= 10')
    @range_2_keywords = @range_2.map(&:keyword)

    
    @range_3 = @semrush_data.where('position >= 11 AND position <= 20')
    @range_3_keywords = @range_3.map(&:keyword)

    @range_4 = @semrush_data.where('position >= 21 AND position <= 50')
    @range_4_keywords = @range_4.map(&:keyword)
    
    @range_5 = @semrush_data.where('position >= 51')
    @range_5_keywords = @range_5.map(&:keyword)
    
    # Data for chart
    start_date = Date.today - 1.months
    end_date = Date.parse('2016-04-22')
    # end_date = Date.today
    
    @chart_traffic_day_keyword_data = []
    start_date.upto(end_date) do |date|
      day_data = SemrushStat.where(engine: 'us', day: date)
      @chart_traffic_day_keyword_data << [date.strftime('%D'), ((day_data.sum(:traffic_percent) / day_data.size))]
    end
    
    @actual_top_keywords_traffic = []
    # data_traffic_desc = SemrushStat.where(engine: 'us', day: Date.today).order('traffic_percent desc').limit(10)
    data_traffic_desc = SemrushStat.where(engine: 'us', day: '2016-03-01').order('traffic_percent desc').limit(10)
    data_traffic_desc.each do |d|
      @actual_top_keywords_traffic << [d.keyword, d.traffic_percent]
    end
    
    @top_volume_keywords = []
    @semrush_data.take(20).each do |d|
      @top_volume_keywords << [d.volume, d.position, d.traffic_percent]
    end
    
    render layout: false
  end
  
  def save_settings
    @semrush_setting = SemrushAppSettings.find_by(dataset_id: params[:semrush_app_settings][:dataset_id])
    if @semrush_setting.present? #if exists -> update settings
      if @semrush_setting.update(params[:semrush_app_settings].permit!)
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    else #else -> new settings
      @semrush_setting = SemrushAppSettings.new(params[:semrush_app_settings].permit!)
      if @semrush_setting.save
        flash[:notice]  = "Settings successfully saved."
      else
        flash[:alert]   = "Settings could not be saved. Please try again."
      end
    end
  end
  
  def update_settings
    settings = AppSetting.find_by(dataset_id: params[:dataset_id])
    if settings.present?
      settings.update(settings: params[:settings])
    else
      settings = AppSetting.create(dataset_id: params[:dataset_id], settings: params[:settings])
    end
    respond_to do |format|
      if settings.errors.blank?
        format.json { render json: { success: true, message: 'Updated App Settings.' }}
      else
        format.json { render json: { success: false, error: settings.errors } }
      end
    end
  end
  
end
