require 'rails_helper'

describe JobadderUser do

  before(:each) do
   JobadderUser.delete_all
  end

  context 'When testing the JobadderUser model' do

    user_id = 1
    email = 'john@email.com'
    user_data_hash = {'id' => 1, 'dataset_id' => 1}
    user_profile_hash = {'first_name' => 'John', 'last_name' => 'Doe'}
    registration_answers_hash = {'question' => 'how are you', 'answer' => 'good'}
    sent_upload_ids_array = [1, 2, 3]


    it 'should pass creating user with all params' do

      user = JobadderUser.new({user_id: user_id,
                               email: email,
                               user_data: user_data_hash,
                               user_profile: user_profile_hash,
                               registration_answers: registration_answers_hash,
                               sent_upload_ids: sent_upload_ids_array})
      user.save

      user_fetched = JobadderUser.find_by_user_id(user_id)

      expect(user_fetched).to have_attributes(:user_id => user_id,
                                              :email => email,
                                              :user_data => user_data_hash,
                                              :user_profile => user_profile_hash,
                                              :registration_answers => registration_answers_hash,
                                              :sent_upload_ids => sent_upload_ids_array)

      puts 'valid user'
    end

    it 'should fail creating user without user_id' do

      user = JobadderUser.new({email: email})

      expect(user).not_to be_valid

      puts 'invalid user - user_id not presented '

    end

    it 'should fail creating user without email' do

      user = JobadderUser.new({user_id: user_id})

      expect(user).not_to be_valid

      puts 'invalid user - email not presented '

    end

    it 'should fail creating users with same id' do
      user1 = JobadderUser.new({user_id: user_id, email: 'john@gmail.com'})
      user1.save
      user2 = JobadderUser.new({user_id: user_id, email: 'jim@gmail.com'})
      user2.save
      expect(user1).to be_valid
      expect(user2).not_to be_valid
      puts 'invalid user - user_id should be unique '
    end

    puts 'JobadderUser spec passes!'
  end


end