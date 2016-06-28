class SaveSemrushData
  def self.save_data(app_setting_id)
    # fake_data = [
                  # {keyword: 'test keyword 1',pos: '1',position_difference: '1',traffic_percent: '0.1',costs_percent: '1',number_of_results: '100',cpc: '1',average_vol: '100',url: 'url1.com'},
                  # {keyword: 'test keyword 2',pos: '2',position_difference: '2',traffic_percent: '0.2',costs_percent: '2',number_of_results: '200',cpc: '2',average_vol: '200',url: 'url2.com'},
                  # {keyword: 'test keyword 3',pos: '3',position_difference: '3',traffic_percent: '0.3',costs_percent: '3',number_of_results: '300',cpc: '3',average_vol: '300',url: 'url3.com'},
                  # {keyword: 'test keyword 4',pos: '4',position_difference: '4',traffic_percent: '0.4',costs_percent: '4',number_of_results: '400',cpc: '4',average_vol: '400',url: 'url4.com'},
                  # {keyword: 'test keyword 5',pos: '5',position_difference: '5',traffic_percent: '0.5',costs_percent: '5',number_of_results: '500',cpc: '5',average_vol: '500',url: 'url5.com'}
                # ]
    
    app_setting = SemrushAppSettings.find(app_setting_id)
    report = Semrush::Report.domain(app_setting.domain)
    engine = app_setting.engine
    start_date = Date.today - app_setting.previous_data.month
    request_rate = app_setting.request_rate
    end_date = Date.today
    if app_setting.has_records?
      organic_report = report.organic(db: app_setting.engine, display_date: Date.today.strftime('%Y%m%d'), limit: app_setting.keyword_amount)
      # organic_report = fake_data;
      organic_report.each do |o|
        app_setting.semrush_stats.create(
          dataset_id: app_setting.dataset_id,
          domain: app_setting.domain,
          keyword: o[:keyword],
          position: o[:pos],
          position_difference: o[:position_difference],
          traffic_percent: o[:traffic_percent],
          costs_percent: o[:costs_percent],
          results: o[:number_of_results],
          cpc: o[:cpc],
          volume: o[:average_vol],
          url: o[:url],
          engine: engine,
          day: Date.today
        )
        app_setting.update(last_petition_at: Date.today)
      end
    else
      (start_date.to_datetime.to_i .. end_date.to_datetime.to_i).step(request_rate.days) do |date|
        date = Time.at(date)
        if date <= Date.today
          organic_report = report.organic(db: app_setting.engine, display_date: date.strftime('%Y%m%%d'), limit: app_setting.keyword_amount)
          # organic_report = fake_data;
          organic_report.each do |o|
            app_setting.semrush_stats.create(
              dataset_id: app_setting.dataset_id,
              domain: app_setting.domain,
              keyword: o[:keyword],
              position: o[:pos],
              position_difference: o[:position_difference],
              traffic_percent: o[:traffic_percent],
              costs_percent: o[:costs_percent],
              results: o[:number_of_results],
              cpc: o[:cpc],
              volume: o[:average_vol],
              url: o[:url],
              engine: engine,
              day: date
            )
          end
          app_setting.update(last_petition_at: date)
        end
      end
    end
  end
end