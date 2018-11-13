require 'rails_helper'

describe JobadderApplicationWorker do

  context 'When testing the JobadderApplicationWorker' do
    let(:sqs_msg) {double message_id: 'fc754df7-9cc2-4c41-96ca-5996a44b771e',
                          body: 'test',
                          delete: nil}
    before(:each) do
      @user = create(:jobadder_user)
      @ja_setting = create(:jobadder_app_setting)
      @key = create(:app_key)
    end
    after(:each) do
      JobadderFieldMapping.delete_all
    end

    it 'should pass upload attachment to update sent_upload_ids' do

      msg = get_message(true)

      worker = JobadderApplicationWorker.new

      ja_service = Jobadder::ClientService.new(@ja_setting)

      application_id = 1

      allow(ja_service).to receive(:add_single_attachment).and_return(true)

      worker.send(:upload_attachments, msg, @user, application_id, ja_service, nil)

      user_fetched = JobadderUser.find_by(user_id: @user.user_id)

      expect(user_fetched.sent_upload_ids.size).to eq(5)

      user_fetched.sent_upload_ids.each do |item|

        expect(item === 1 || item === 2 || item === 3 || item === 4 || item === 5).to be_truthy

      end

    end

    it 'should pass upload attachment not to update sent_upload_ids' do

      msg = get_message(false)

      worker = JobadderApplicationWorker.new

      ja_service = Jobadder::ClientService.new(@ja_setting)

      application_id = 1

      allow(ja_service).to receive(:add_single_attachment).and_return(true)

      worker.send(:upload_attachments, msg, @user, application_id, ja_service, nil)

      user_fetched = JobadderUser.find_by(user_id: @user.user_id)

      expect(user_fetched.sent_upload_ids.size).to eq(3)

      user_fetched.sent_upload_ids.each do |item|

        expect(item === 1 || item === 2 || item === 3).to be_truthy

      end

    end

    it 'should pass perform sqs message send new attachments' do

      msg = get_message(true)

      worker = JobadderApplicationWorker.new

      candidate_id = 1

      stub_request(:get, "https://api.jobadder.com/v2/candidates?email=#{@user.email}").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => '{"items" : [{"candidateId": 1}]}', headers: {"Content-Type" => "application/json"})

      stub_request(:get, "https://api.jobadder.com/v2/candidates/fields/custom").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "https://api.jobadder.com/v2/candidates").
          with(:body => "{\"firstName\":\"Johny\",\"lastName\":\"Apple\",\"email\":null,\"source\":null}",
               :headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 201, :body => "{\"candidateId\" : #{candidate_id}}", headers: {"Content-Type" => "application/json"})

      stub_request(:get, "https://api.jobadder.com/v2/jobs/1277/applications").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "{\"items\" : [{\"candidate\" : {\"candidateId\": 2}}]}", headers: {"Content-Type" => "application/json"})

      stub_request(:post, "https://api.jobadder.com/v2/jobs/1277/applications").
          with(:body => "{\"candidateId\":[1],\"source\":\"VolcanicApp\"}",
               :headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "{\"items\" : [{\"applicationId\" : 12345}]}", :headers => {"Content-Type" => "application/json"})

      stub_request(:get, "https://api.jobadder.com/v2/worktypes").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, "http://test.localhost.volcanic.co/api/v1/users/1.json?api_key=abc123").
          with(:headers => {'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "", :headers => {})

      allow(worker).to receive(:add_single_attachment).and_return(true)

      worker.send(:perform, sqs_msg, msg)

      user_fetched = JobadderUser.find_by(user_id: @user.user_id)

      expect(user_fetched.sent_upload_ids.size).to eq(5)

      user_fetched.sent_upload_ids.each do |item|

        expect(item === 1 || item === 2 || item === 3 || item === 4 || item === 5).to be_truthy

      end

    end
    it 'should pass perform sqs message, not to send old attachments' do

      msg = get_message(false)

      worker = JobadderApplicationWorker.new

      candidate_id = 1

      stub_request(:get, "https://api.jobadder.com/v2/candidates?email=#{@user.email}").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => '{"items" : []}', headers: {"Content-Type" => "application/json"})

      stub_request(:get, "https://api.jobadder.com/v2/candidates/fields/custom").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'User-Agent' => 'VolcanicJobadderApp'}).
          to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "https://api.jobadder.com/v2/candidates").
          with(:body => "{\"firstName\":\"Johny\",\"lastName\":\"Apple\",\"email\":null,\"source\":null}",
               :headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 201, :body => "{\"candidateId\" : #{candidate_id}}", headers: {"Content-Type" => "application/json"})

      stub_request(:get, "https://api.jobadder.com/v2/jobs/1277/applications").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "{\"items\" : [{\"candidate\" : {\"candidateId\": 2}}]}", headers: {"Content-Type" => "application/json"})

      stub_request(:post, "https://api.jobadder.com/v2/jobs/1277/applications").
          with(:body => "{\"candidateId\":[1],\"source\":\"VolcanicApp\"}",
               :headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "{\"items\" : [{\"applicationId\" : 12345}]}", :headers => {"Content-Type" => "application/json"})

      stub_request(:get, "https://api.jobadder.com/v2/worktypes").
          with(:headers => {'Authorization' => "Bearer #{@ja_setting.access_token}", 'Content-Type' => 'application/json'}).
          to_return(:status => 200, :body => "", :headers => {})

      allow(worker).to receive(:add_single_attachment).and_return(true)

      worker.send(:perform, sqs_msg, msg)

      user_fetched = JobadderUser.find_by(user_id: @user.user_id)

      expect(user_fetched.sent_upload_ids.size).to eq(3)

      user_fetched.sent_upload_ids.each do |item|

        expect(item === 1 || item === 2 || item === 3).to be_truthy

      end

    end

    it 'should get registration answer files' do

      worker = JobadderApplicationWorker.new

      JobadderFieldMapping.create(:jobadder_app_setting_id => @ja_setting.id, :jobadder_field_name => 'Other', :registration_question_reference => 'file-upload-1')
      JobadderFieldMapping.create(:jobadder_app_setting_id => @ja_setting.id, :jobadder_field_name => 'Resume', :registration_question_reference => 'file-upload-2')
      JobadderFieldMapping.create(:jobadder_app_setting_id => @ja_setting.id, :jobadder_field_name => 'First Name', :registration_question_reference => 'first-name')
      JobadderFieldMapping.create(:jobadder_app_setting_id => @ja_setting.id, :jobadder_field_name => 'Last Name', :registration_question_reference => 'last-name')


      reg_answer_files = worker.send(:get_reg_answer_files, get_reg_answers, @ja_setting, @key)

      expect(reg_answer_files.length).to eq(2)

      expect(reg_answer_files[0]['name']).to eq('file-upload-1')
      expect(reg_answer_files[1]['name']).to eq('file-upload-2')
      expect(reg_answer_files[0]['url']).to eq('http://test.localhost.volcanic.co/s3/abc123')
      expect(reg_answer_files[1]['url']).to eq('http://test.localhost.volcanic.co/s3/def456')
      expect(reg_answer_files[0]['type']).to eq('Other')
      expect(reg_answer_files[1]['type']).to eq('Resume')

    end

  end


  def get_message(new_files)

    cv = fixture_file_upload('files/cv_sample.pdf', 'application/pdf')
    cover_letter = fixture_file_upload('files/cover_letter_sample.pdf', 'application/pdf')

    if new_files
      # return files which weren't uploaded previously
      msg = {'site' => 1,
             'user' => {
                 'id' => @user.user_id,
                 'dataset_id' => @ja_setting.dataset_id
             },

             'job' => {
                 'id' => 6,
                 'dataset_id' => @ja_setting.dataset_id,
                 'job_reference' => 1277,
                 'site_id' => 1,
             },
             'application' => {

                 'id' => 11,
                 'dataset_id' => @ja_setting.dataset_id,
                 'job_id' => 6,
                 'user_id' => @user.id,
                 'cv_upload_id' => 5,
                 'covering_letter_upload_id' => 4,
                 'status' => 'new',
                 'uploads' => {
                     'cv_url' => cv.path(),
                     'cv_name' => 'CV_sample.pdf',
                     'cover_letter_url' => cover_letter.path(),
                     'cover_letter_name' => 'Cover_Letter_sample.pdf'
                 }
             },
             'dataset_id' => @ja_setting.dataset_id
      }
      return msg
    else
      msg = {'site' => 1,
             'user' => {
                 'id' => @user.user_id
             },

             'job' => {
                 'id' => 6,
                 'dataset_id' => @ja_setting.dataset_id,
                 'job_reference' => 1277,
                 'site_id' => 1,
             },
             'application' => {

                 'id' => 11,
                 'dataset_id' => @ja_setting.dataset_id,
                 'job_id' => 6,
                 'user_id' => @user.id,
                 'cv_upload_id' => 1,
                 'covering_letter_upload_id' => 2,
                 'status' => 'new',
                 'uploads' => {
                     'cv_url' => 'www.example.com/files/cv',
                     'cv_name' => 'CV_sample.pdf',
                     'cover_letter_url' => 'www.example.com/files/cover_letter',
                     'cover_letter_name' => 'Cover_Letter_sample.pdf'
                 }
             },
             'dataset_id' => @ja_setting.dataset_id
      }
      return msg
    end
  end

  def get_reg_answers
    return [
        {"file-upload-1" => "/s3/abc123"},
        {"file-upload-2" => "/s3/def456"},
        {"first-name" => "Johny"},
        {"last-name" => "Apple"}
    ]

  end

end