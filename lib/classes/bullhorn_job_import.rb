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
      settings = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
      if settings.present? && settings['import_jobs'].present? && settings['import_jobs'] == true
        client =  Bullhorn::Rest::Client.new(
          username: settings.bh_username,
          password: settings.bh_password,
          client_id: settings.bh_client_id,
          client_secret: settings.bh_client_secret
        )
        parse_jobs(client)
        # @job_data = query_job_orders(client, false)
        # @job_data.each do |j|
        #   puts "--- #{j.id}"
        # end
        # puts "--- @job_data.size = #{@job_data.size}"
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
      settings = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
      if settings.present? && settings['import_jobs'].present? && settings['import_jobs'] == true
        client =  Bullhorn::Rest::Client.new(
          username: settings.bh_username,
          password: settings.bh_password,
          client_id: settings.bh_client_id,
          client_secret: settings.bh_client_secret
        )
        parse_jobs_for_delete(client)
      end
    end

    puts '- END delete_jobs'
  end

  def parse_jobs(client)
    settings = BullhornAppSetting.find_by(dataset_id: @key.app_dataset_id)
    field_mappings = settings.bullhorn_field_mappings.job
    job_references = volcanic_job_references
    
    @job_data = query_job_orders(client, false, field_mappings.map(&:bullhorn_field_name).reject { |m| m.empty? })
    # jobs = @job_data.xpath("//item")
    @non_public_jobs_count = 0
    @job_data.each do |job|
      if settings.uses_public_filter? && job.isPublic == 0

        #make sure the job is deleted if already published in Volcanic
        if job_references.include?(job.id.to_s)
          @job_payload = Hash.new
          @job_payload["job[api_key]"] = @key.api_key
          @job_payload['job[job_reference]'] = job.id
          post_payload_for_delete(@job_payload)
        end

        @non_public_jobs_count = ( @non_public_jobs_count + 1 ) 
        next 
      end
      
      unless job.isDeleted
        @job_payload = Hash.new
        @job_payload["job[api_key]"] = @key.api_key

        puts "--- job.title = #{job.title}"
        @job_payload['job[job_title]'] = job.title
        # CORPORATE USER?
        puts "--- job.owner = #{job.owner}"
        c_user = client.corporate_user(job.owner.id)
        # app_email = job.xpath('author').text.strip.split.first.strip
        @job_payload['job[application_email]'] = @job_payload['job[contact_email]'] = c_user.data.email
        @job_payload['job[contact_name]'] = "#{job.owner.firstName} #{job.owner.lastName}"

        @job_payload['job[created_at]'] = Time.at(job.dateAdded / 1000).to_datetime.to_s

        # @job_payload['job[job_reference]'] = job.externalID
        @job_payload['job[job_reference]'] = job.id
        # address = job.address.map{ |a| a[0] == 'countryID' ? get_country(a[1].to_s) : a[1] }.reject{ |a| a.blank? }.join(', ')
        city = job.address.city
        country = get_country(job.address.countryID.to_s)
        @job_payload['job[job_location]'] = [city, country].reject{ |a| a.blank? }.join(', ')
        @job_payload['job[job_type]'] = job.employmentType

        salary_val = job.salary > 0 ? job.salary : nil
        @job_payload['job[salary_low]'] = salary_val

        # MAX SALARY and SALARY FREE are set to configurable custom fields:

        field_mappings.each do |fm|

          puts "--- job.#{fm.bullhorn_field_name} = #{job.send(fm.bullhorn_field_name)}"
          
          case fm.job_attribute
          when 'salary_free'
            @job_payload["job[salary_free]"] = job.send(fm.bullhorn_field_name)
          when 'salary_high'
            if job.send(fm.bullhorn_field_name).present? && job.send(fm.bullhorn_field_name).to_i != 0
              @job_payload['job[salary_high]'] = job.send(fm.bullhorn_field_name)
            else
              @job_payload['job[salary_high]'] = salary_val
            end
          when 'discipline'
            case fm.bullhorn_field_name
            when 'businessSectors'
              disciplines = []
              job.businessSectors.data.each do |bs|
                # puts "--- bs[:id] = #{bs[:id]}"
                b_sector = client.business_sector(bs[:id])
                # puts "--- b_sector = #{b_sector.inspect}"
                disciplines << b_sector.data.name.strip
              end
              discipline_list = disciplines.join(', ')
            when 'categories'
              disciplines = job.categories.data.map(&:name)
              discipline_list = disciplines.join(', ')
            else
              discipline_list = job.send(fm.bullhorn_field_name)
            end
            
            @job_payload['job[discipline]'] = discipline_list.strip if discipline_list.present?
          end
        end
        
        salary_per = 'hour' if job.salaryUnit == 'Per Hour'
        salary_per = 'day' if job.salaryUnit == 'Per Day'
        @job_payload['job[salary_per]'] = salary_per

        @job_payload['job[job_description]'] = job.publicDescription.present? ? job.publicDescription : job.description

        puts "--- job.isOpen = #{job.isOpen}"
        if job.isOpen
          puts '--- JOB IS OPEN'
          # Expiry = date + 365 days
          begin
            date = Date.parse(@job_payload['job[created_at]'])
            @job_payload['job[expiry_date]'] = (date + 365.days).to_s
          rescue Exception => e
            puts "[WARN] #{e}"
            @job_payload['job[expiry_date]'] = (Date.today + 365.days).to_s
          end
        else
          puts '--- JOB IS CLOSED'
          @job_payload['job[expiry_date]'] = (Date.today - 1.day).to_s
        end

        bullhorn_job = @key.bullhorn_jobs.find_or_create_by(bullhorn_uid: @job_payload['job[job_reference]'])
        begin
          bullhorn_job.update_attribute :job_params, @job_payload
        rescue ActiveRecord::StatementInvalid
          bullhorn_job.update_attribute :job_params, 'Payload too large to save'
        end

        puts "--- @job_payload = #{@job_payload.inspect}"
        if @job_payload["job[discipline]"].blank?
          bullhorn_job.update_attribute :error, true
        else
          post_payload(@job_payload) 
        end
      else
        puts "--- #{job.title} has been Deleted"
      end
    end

    puts "Total data size = #{@job_data.length} jobs"
    puts "Total private jobs skipped size = #{@non_public_jobs_count} jobs"
    
    puts "Updating report entries"
    @key.update_bullhorn_report_job_entries
  end

  def parse_jobs_for_delete(client)
    @job_data = query_job_orders(client, true)
    # jobs = @job_data.xpath("//item")
    
    job_references = volcanic_job_references

    @job_data.each do |job|
      if (job.isDeleted || job.status == 'Archive') && job_references.include?(job.id.to_s)
        @job_payload = Hash.new
        @job_payload["job[api_key]"] = @key.api_key
        @job_payload['job[job_reference]'] = job.id

        # puts "--- @job_payload = #{@job_payload.inspect}"
        post_payload_for_delete(@job_payload)
      end
    end

    puts "Total data size = #{@job_data.length} jobs"
  end

  private

  def query_job_orders(client, is_deleted, custom_fields = [])
    # Bullhorn only returns 200 jobs per query, so if 200 is received, assume there are more an increase offset and repeat query. 
    # Stop when less than 200 received in a query, and return concatenated results

    offset = 0
    results = 200 # prime the loop

    complete_data = []

    fields = (%w(id title owner businessSectors dateAdded externalID address employmentType benefits salary description publicDescription isOpen isDeleted isPublic status salaryUnit) + custom_fields).uniq.join(',')
    
    while results == 200
      if is_deleted
        jobs = client.query_job_orders(where: "isDeleted = #{is_deleted} OR status = 'Archive'", fields: fields, count: 200, start: offset)
      else
        jobs = client.query_job_orders(where: "isDeleted = false AND status <> 'Archive'", fields: fields, count: 200, start: offset)
      end
      
      puts "Received #{jobs["count"]}"
      puts "Received 200 - possibly another page" if jobs["count"] >= 200

      results = jobs["count"]
      offset += 200
      complete_data.concat jobs.data
    end
    complete_data
  end

  def post_payload(payload)
    # net = Net::HTTP.new(@key.host, 80)
    # # net = Net::HTTP.new(@key.host, 3000)
    # request = Net::HTTP::Post.new("/api/v1/jobs.json")
    # request.set_form_data( payload )
    # net.read_timeout = net.open_timeout = 10

    bullhorn_job = @key.bullhorn_jobs.find_by(bullhorn_uid: payload['job[job_reference]'])

    begin
      # response = net.start do |http|
      #   http.request(request)
      # end

      response = HTTParty.post("#{@key.protocol}#{@key.host}/api/v1/jobs.json", { body: payload })

      bullhorn_job.update_attribute(:error, true) unless response.code.to_i == 200

      puts "#{response.code} - #{response.read_body}"
      return response.code.to_i == 200
    rescue Exception => e
      puts "[FAIL] http.request failed to post payload: #{e}"
    end
  end

  def post_payload_for_delete(payload)

    begin
      response = HTTParty.post("#{@key.protocol}#{@key.host}/api/v1/jobs/delete.json", { body: payload })

      @key.bullhorn_report_entry.increment_count(:job_delete) if response.code.to_i == 200

      puts "#{response.code} - #{response.read_body}"
      return response.code.to_i == 200
    rescue Exception => e
      puts "[FAIL] http.request failed to post payload: #{e}"
    end
  end

  def get_country(country_id)
    bullhorn_country_array =  [
      ["United States","1"],
      ["Afghanistan","2185"],
      ["Albania","2186"],
      ["Algeria","2187"],
      ["Andorra","2188"],
      ["Angola","2189"],
      ["Antartica","2190"],
      ["Antigua and Barbuda","2191"],
      ["Argentina","2192"],
      ["Armenia","2193"],
      ["Australia","2194"],
      ["Austria","2195"],
      ["Azerbaijan","2196"],
      ["Bahamas","2197"],
      ["Bahrain","2198"],
      ["Bangladesh","2199"],
      ["Barbados","2200"],
      ["Belarus","2201"],
      ["Belgium","2202"],
      ["Belize","2203"],
      ["Benin","2204"],
      ["Bhutan","2205"],
      ["Bolivia","2206"],
      ["Bosnia Hercegovina","2207"],
      ["Botswana","2208"],
      ["Brazil","2209"],
      ["Brunei Darussalam","2210"],
      ["Bulgaria","2211"],
      ["Burkina Faso","2212"],
      ["Burundi","2213"],
      ["Cambodia","2214"],
      ["Cameroon","2215"],
      ["Canada","2216"],
      ["Cape Verde","2217"],
      ["Central African Republic","2218"],
      ["Chad","2219"],
      ["Chile","2220"],
      ["China","2221"],
      ["Columbia","2222"],
      ["Comoros","2223"],
      ["Costa Rica","2226"],
      ["Cote d'Ivoire","2227"],
      ["Croatia","2228"],
      ["Cuba","2229"],
      ["Cyprus","2230"],
      ["Czech Republic","2231"],
      ["Denmark","2232"],
      ["Djibouti","2233"],
      ["Dominica","2234"],
      ["Dominican Republic","2235"],
      ["Ecuador","2236"],
      ["Egypt","2237"],
      ["El Salvador","2238"],
      ["Equatorial Guinea","2239"],
      ["Eritrea","2240"],
      ["Estonia","2241"],
      ["Ethiopia","2242"],
      ["Fiji","2243"],
      ["Finland","2244"],
      ["France","2245"],
      ["Gabon","2246"],
      ["Georgia","2248"],
      ["Germany","2249"],
      ["Ghana","2250"],
      ["Greece","2251"],
      ["Greenland","2252"],
      ["Grenada","2253"],
      ["Guinea","2255"],
      ["Guinea-Bissau","2256"],
      ["Guyana","2257"],
      ["Haiti","2258"],
      ["Honduras","2259"],
      ["Hungary","2260"],
      ["Iceland","2261"],
      ["India","2262"],
      ["Indonesia","2263"],
      ["Iran","2264"],
      ["Iraq","2265"],
      ["Ireland","2266"],
      ["Israel","2267"],
      ["Italy","2268"],
      ["Jamaica","2269"],
      ["Japan","2270"],
      ["Jordan","2271"],
      ["Kazakhstan","2272"],
      ["Kenya","2273"],
      ["Korea; Democratic People's Republic Of (North)","2274"],
      ["Korea; Republic Of (South)","2275"],
      ["Kuwait","2276"],
      ["Kyrgyzstan","2277"],
      ["Lao People's Democratic Republic","2278"],
      ["Latvia","2279"],
      ["Lebanon","2280"],
      ["Lesotho","2281"],
      ["Liberia","2282"],
      ["Liechtenstein","2284"],
      ["Lithuania","2285"],
      ["Luxembourg","2286"],
      ["Macau","2287"],
      ["Macedonia","2288"],
      ["Madagascar","2289"],
      ["Malawi","2290"],
      ["Malaysia","2291"],
      ["Mali","2292"],
      ["Malta","2293"],
      ["Mauritania","2294"],
      ["Mauritius","2295"],
      ["Mexico","2296"],
      ["Micronesia; Federated States of","2297"],
      ["Monaco","2299"],
      ["Mongolia","2300"],
      ["Morocco","2301"],
      ["Mozambique","2302"],
      ["Myanmar","2303"],
      ["Namibia","2304"],
      ["Nepal","2305"],
      ["Netherlands","2306"],
      ["New Zealand","2307"],
      ["Nicaragua","2308"],
      ["Niger","2309"],
      ["Nigeria","2310"],
      ["Norway","2311"],
      ["Oman","2312"],
      ["Pakistan","2313"],
      ["Palau","2314"],
      ["Panama","2315"],
      ["Papua New Guinea","2316"],
      ["Paraguay","2317"],
      ["Peru","2318"],
      ["Philippines","2319"],
      ["Poland","2320"],
      ["Portugal","2321"],
      ["Qatar","2322"],
      ["Romania","2323"],
      ["Russian Federation","2324"],
      ["Rwanda","2325"],
      ["Saint Lucia","2326"],
      ["San Marino","2327"],
      ["Saudi Arabia","2328"],
      ["Senegal","2329"],
      ["Seychelles","2331"],
      ["Sierra Leone","2332"],
      ["Singapore","2333"],
      ["Slovakia","2334"],
      ["Slovenia","2335"],
      ["Solomon Islands","2336"],
      ["Somalia","2337"],
      ["South Africa","2338"],
      ["Spain","2339"],
      ["Sri Lanka","2340"],
      ["Sudan","2341"],
      ["Suriname","2342"],
      ["Swaziland","2343"],
      ["Sweden","2344"],
      ["Switzerland","2345"],
      ["Tajikistan","2348"],
      ["Tanzania","2349"],
      ["Thailand","2350"],
      ["Togo","2351"],
      ["Trinidad and Tobago","2352"],
      ["Tunisia","2353"],
      ["Turkey; Republic of","2354"],
      ["Turkmenistan","2355"],
      ["Uganda","2356"],
      ["Ukraine","2357"],
      ["United Arab Emirates","2358"],
      ["United Kingdom","2359"],
      ["Uruguay","2360"],
      ["Uzbekistan","2361"],
      ["Vatican City","2362"],
      ["Venezuela","2363"],
      ["Vietnam","2364"],
      ["Yugoslavia","2367"],
      ["Zaire","2368"],
      ["Zambia","2369"],
      ["Zimbabwe","2370"],
      ["Guatemala","2371"],
      ["Bermuda","2372"],
      ["Aruba","2373"],
      ["Puerto Rico","2374"],
      ["Taiwan","2375"],
      ["Guam","2376"],
      ["Hong Kong SAR","NU2377"],
      ["None Specified","NO2378"],
      ["Cayman Islands","2379"]
    ]
    array_item = bullhorn_country_array.select{ |name, id| id == country_id }
    if array_item.present?
      array_item.first[0]
    end
  end

  def volcanic_job_references
    url = "#{@key.protocol}#{@key.host}/api/v1/jobs/job_references.json"
    response = HTTParty.get(url)

    if response.code == 200
      response.parsed_response.map { |r| r['job_reference'] }
    else
      []
    end
  end
end
