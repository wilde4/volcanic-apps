FactoryGirl.define do
  factory :jobadder_app_setting do
    dataset_id 2
    ja_client_id 's4voea33fvrepcbzgtil2yt3di'
    ja_client_secret '5217621ccc8911e8a8d5f28011'
    app_url 'www.example.com'
    access_token '669ffc69f8a360c61c06c7f87672a280'
    refresh_token '12499b75ab67dd226ad82ea8e8558b44'
    access_token_expires_at DateTime.parse(1.hour.from_now.to_s)
  end
end