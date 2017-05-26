# BullhornJobImport.new.import_jobs
# BullhornJobImport.new.delete_jobs
class BullhornJobImport

  def import_jobs
    
    puts '- BEGIN import_jobs'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'bullhorn')

    registered_hosts.each do |reg_host|
      puts "Polling for: #{reg_host.host}"
      @key = reg_host

      @bullhorn_setting = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
      @bullhorn_service = Bullhorn::ClientService.new(@bullhorn_setting) if @bullhorn_setting.present?

      if @bullhorn_service.present?
        @bullhorn_service.import_client_jobs
      end

    end

    puts '- END import_jobs'
  end

  def delete_jobs
    puts '- BEGIN delete_jobs'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'bullhorn')

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

end
