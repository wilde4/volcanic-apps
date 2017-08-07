# BullhornV2JobImport.new.import_jobs
# BullhornV2JobImport.new.delete_jobs
# BullhornV2JobImport.new.expire_jobs
class BullhornV2JobImport

  def import_jobs
    
    puts '- BEGIN import_jobs'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'bullhorn_v2')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host

      @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
      @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present? && @bullhorn_setting['import_jobs'] == true

      if @bullhorn_service.present?
        @bullhorn_service.import_client_jobs
      end

    end

    puts '- END import_jobs'
  end

  def delete_jobs
    puts '- BEGIN delete_jobs'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'bullhorn_v2')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host

      @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
      @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

      if @bullhorn_service.present?
        @bullhorn_service.delete_client_jobs
      end
    end

    puts '- END delete_jobs'
  end

  def expire_jobs
    puts '- BEGIN expire_jobs'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'bullhorn_v2')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host

      @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)

      if @bullhorn_setting.expire_closed_jobs?
        @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

        if @bullhorn_service.present?
          @bullhorn_service.expire_client_jobs
        end
      else
        puts " --------- Expire Bullhorn's Closed jobs setting not active for #{reg_host.host}"
      end

    end

    puts '- END expire_jobs'
  end

end
