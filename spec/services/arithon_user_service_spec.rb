require 'rails_helper'

describe Arithon::UserService do

  before(:each) do

    @key = create(:arithon_app_key)

  end

  after(:each) do

    Key.delete_all

  end


  context 'When testing the Arithon::UserService ' do

    it 'should pass map attributes - no GDPS document present' do

      user = create(:gdpr_not_presented)

      service = Arithon::UserService.new(user, {}, @key)
      attributes = service.send(:map_contact_attributes)

      expect(attributes[:gdprAccept]).to be_nil


    end

    it 'should pass map attributes - accepted GDPR' do

      user = create(:gdpr_accepted)

      service = Arithon::UserService.new(user, {}, @key)
      attributes = service.send(:map_contact_attributes)

      expect(attributes[:gdprAccept]).to eq('Yes')


    end
    it 'should pass map attributes - not accepted GDPR' do

      user = create(:gdpr_not_accepted)

      service = Arithon::UserService.new(user, {}, @key)
      attributes = service.send(:map_contact_attributes)

      expect(attributes[:gdprAccept]).to eq('No')


    end


  end

end