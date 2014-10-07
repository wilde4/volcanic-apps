class TalentRoverApp
  def self.poll_jobs_feed
    puts '- BEGIN poll_jobs_feed'

    # Find who has registered to use TR:
    registered_hosts = Key.where(app_name: 'talent_rover')

    registered_hosts.each do |reg_host|
      @key = reg_host
      parse_jobs
    end

    puts '- END poll_jobs_feed'
  end

  def self.parse_jobs
    @job_data = get_xml
    jobs = @job_data.xpath("//job")
    
    jobs.each do |job|
      job_payload = Hash.new
      job_payload["job[api_key]"] = @key.api_key

      # Map the general attributes onto the payload
      attribute_mapping.each do |k,v|
        child = job.xpath("#{k}")
        job_payload["job[#{v}]"] = child.text if child.text.present?
      end

      if job_payload["job[discipline]"].present?
        job_payload["job[discipline]"] = job_payload["job[discipline]"].to_url
      end

      # Map the job location, drop empties and comma-join:
      addr_nodes = job.xpath("city | state | country | postalcode")
      job_location = addr_nodes.map(&:text).reject(&:empty?).join(', ')
      job_payload["job[job_location]"] = job_location if job_location.present?
      post_payload(job_payload) unless job_payload["job[discipline]"].blank?
    end
  end

private
  def self.get_xml
    settings = AppSetting.find_by(dataset_id: @key.app_dataset_id)
    doc = Nokogiri::XML(open(settings.settings["Feed URL"]))
  end

  def self.post_payload(payload)
    #net = Net::HTTP.new(@key.host, 80)
    net = Net::HTTP.new(@key.host, 80)
    request = Net::HTTP::Post.new("/api/v1/jobs.json")
    request.set_form_data( payload )
    net.read_timeout = net.open_timeout = 10

    response = net.start do |http|
      http.request(request)
    end

    if response.code.to_i != 200
      puts "#{response.code} - #{response.read_body}"
      return false
    else
      return true
    end
  end

  def self.attribute_mapping
    {
      title: 'job_title',
      referencenumber: 'job_reference',
      url: 'application_url',
      description: 'job_description',
      salary: 'salary_free',
      jobtype: 'job_type',
      category: 'discipline'
    }
  end
end