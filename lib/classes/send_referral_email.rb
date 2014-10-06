=begin
class SendReferralEmail

  def self.send_funds_email(dataset_id)
    # Run it for the specified dataset or all:
    dataset_ids = dataset_id.present? ? [dataset_id] : Referral.select(:dataset_id).distinct

    dataset_ids.each do |dataset_id|
      get_key(dataset_id)

      Referral.by_dataset(dataset_id).each do |referral|
        event_str = referral.funds_owed > 0 ? 'graduate_owed_fees' : 'graduate_not_owed_fees'
        
        # curl -X POST -H "Content-Type: application/json" -d '{"api_key" : "42a8871d56d39ab3181a39cf95507ba6", "event_name" : "graduate_owed_fees", "user_id" : "2433", "outstanding_amount" : '45.50', "amount_earned_already" : '30.00'}' http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json
        # @response = HTTParty.post('http://evergrad.localhost.volcanic.co:3000/api/v1/event_services.json', {:body => {event_name: 'graduate_owed_fees', api_key: @key.api_key, user_id: referer.user_id, outstanding_amount: '45.50', amount_earned_already: '30.00'}, :headers => { 'Content-Type' => 'application/json' }})
        @response = HTTParty.post(
          'http:///api/v1/event_services.json', {
            :body =>
            {
              event_name: event_str,
              api_key: @key.api_key,
              user_id: referral.user_id,
              outstanding_amount: referral.funds_owed,
              amount_earned_already: referral.funds_earned
            },
          })
      end
    end
  end

private 

  def self.get_key(dataset_id)
    @key = Key.find_by(app_dataset_id: dataset_id, app_name: 'referral')
  end

end
=end