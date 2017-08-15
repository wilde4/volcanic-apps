class DataImport::RegistrationQuestionsController < ApplicationController
  before_action :authenticate_profile!
  before_action :set_profile
  layout "data_import"

  def index
    require 'net/http'
    
    # if Rails.env.development? 
    #   uri = URI("http://jobsatteam.localhost.volcanic.co:3000/api/v1/user_groups.json")
    # else
      uri = URI("http://" + @profile.host + "/api/v1/user_groups.json")
    # end

    params = { :api_key => @profile.api_key }
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)

    # Compensate for 301 redirects from http to https
    if res.is_a? Net::HTTPMovedPermanently
      uri = URI(res['location'])
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
    end
    @response = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  
    @records = 0

    # Remove questions that no longer exist
    prune_questions(@response)
    
    @response.each do |user_group|
  
      
      user_group["registration_question_groups"].each do |registration_question_group|
        registration_question_group["registration_questions"].each do |registration_question|
          
          conditions = { 
            :user_group_id => user_group["id"],
            :reference => registration_question["reference"],
          }

          # pp = @profile.registration_questions.find(:first, :conditions => conditions) ||  @profile.registration_questions.create(conditions)
          question = @profile.registration_questions.where(conditions).first_or_create
          
          @records += 1 if question.update_attributes({
            :core_reference => registration_question["core_reference"],
            :label => registration_question["label"],
            :user_group_name => user_group["name"],
            :uid => registration_question["id"]
          })



        end
      end

    end
      # [0]["registration_question_groups"][0]["registration_questions"]
    
  end

  private

  def prune_questions(response)
    registration_question_ids = response.map { |user_group| user_group["registration_question_groups"].map { |registration_question_group| registration_question_group["registration_questions"].map { |registration_question| registration_question["id"] } } }.flatten
    dead_questions = @profile.registration_questions.where.not( uid: registration_question_ids )
    @removed_questions_count = dead_questions.count
    dead_questions.destroy_all
  end

end
