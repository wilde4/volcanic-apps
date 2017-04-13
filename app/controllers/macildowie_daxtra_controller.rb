class MacildowieDaxtraController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json, :csv

  def save_user
    @user = MacDaxtraUser.find_by(user_id: params[:user][:id])
    if @user.present?
      @user_profile = params[:user_profile]
      if @user.update(email: params[:user][:email], user_group_name: legacy_user_type, user_profile: @user_profile, registration_answers: params[:registration_answer_hash])
        render json: { success: true, user_id: @user.id }
      else
        create_log(@user, nil, 'save_user', nil, @user.errors.full_messages.join(', '), nil, true, true)
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    else
      @user = MacDaxtraUser.new
      @user.user_id = params[:user][:id]
      @user.email = params[:user][:email]

      if params[:user][:user_group_name].present?
        @user.user_group_name = params[:user][:user_group_name]
      else
        @user.user_group_name = params[:user][:user_type] #legacy support
      end

      @user.user_profile = params[:user_profile]
      @user.registration_answers = params[:registration_answer_hash]

      if @user.save
        render json: { success: true, user_id: @user.id }
      else
        create_log(@user, nil, 'save_user', nil, @user.errors.full_messages.join(', '), nil, true, true)
        render json: { success: false, status: "Error: #{@user.errors.full_messages.join(', ')}" }
      end
    end
  end

  def save_job
    @job = MacDaxtraJob.find_by(job_id: params[:job][:id])
    if @job.present?
      if @job.update(
        job: params[:job], 
        job_type: params[:jobtype], 
        disciplines: params[:disciplines]
      )
        render json: { success: true, job_id: @job.id }
      else
        create_log(@job, nil, 'save_job', nil, @job.errors.full_messages.join(', '), nil, true, true)
        render json: { success: false, status: "Error: #{@job.errors.full_messages.join(', ')}" }
      end
    else
      @job = MacDaxtraJob.new
      @job.job_id = params[:job][:id]
      @job.job = params[:job]
      @job.job_type = params[:job_type]
      @job.disciplines = params[:disciplines]

      if @job.save
        render json: { success: true, job_id: @job.id }
      else
        create_log(@job, nil, 'save_job', nil, @job.errors.full_messages.join(', '), nil, true, true)
        render json: { success: false, status: "Error: #{@job.errors.full_messages.join(', ')}" }
      end
    end
  end

  def email_data
    @user = MacDaxtraUser.find_by(user_id: params[:user_id])
    @name = "#{@user.user_profile[:first_name]} #{@user.user_profile[:last_name]}"

    if params[:email_name] == 'new_candidate'
      @headers = {
        "X-Aplitrak-Original-From-Address" => @user.email,
        "X-Aplitrak-Original-Jobtitle" => @user.registration_answers["current-job-title"].present? ? @user.registration_answers["current-job-title"] : "No Job Title Given",
        "X-Aplitrak-Job-Type" => job_type,
        "X-Aplitrak-Itris_discipline" => discipline_of_interest,
        "X-Aplitrak-Salary_form" => salary_choice
      }
      if @user.user_group_name == 'candidate'
        @subject = "#{job_type}/[NEW CANDIDATE]/NEWC/#{@name}/#{discipline_of_interest}"
        @headers["X-Aplitrak-Responding-Board"] = "NEWC"
        @headers["X-Aplitrak-Responding-Board-Name"] = "newcandidate"
      elsif @user.user_group_name == 'dream_job'
        @subject = "#{job_type}/Dream Job/DJ/#{@name}/#{discipline_of_interest}"
        @headers["X-Aplitrak-Responding-Board"] = "DJ"
        @headers["X-Aplitrak-Responding-Board-Name"] = "dreamjob"
      end
    elsif params[:email_name] == 'updated_cv_from_candidate' or params[:email_name] == 'updated_candidate'
      @subject = "#{job_type}/Updated/UPD/#{@name}/#{discipline_of_interest}"
      @headers = {
        "X-Aplitrak-Original-From-Address" => @user.email,
        "X-Aplitrak-Original-Jobtitle" => @user.registration_answers["current-job-title"].present? ? @user.registration_answers["current-job-title"] : "No Job Title Given",
        "X-Aplitrak-Job-Type" => job_type,
        "X-Aplitrak-Itris_discipline" => discipline_of_interest,
        "X-Aplitrak-Salary_form" => salary_choice,
        "X-Aplitrak-Responding-Board" => "UPD",
        "X-Aplitrak-Responding-Board-Name" => "updated"
      }
    elsif params[:email_name] == 'apply_for_vacancy'
      @job = MacDaxtraJob.find_by(job_id: params[:job_id])
      @subject = "#{@job.job_type}/#{@job.job["job_title"]}/#{@job.job["job_reference"]}/Macildowie New/5671/#{@job.job["contact_name"]}/#{@job.disciplines.last["name"]}"
      @headers = {
        "X-Mailer" => "Aplitrak Responce Management v2 (codename Apil2)",
        'X-Aplitrak-Responding-Board' => "5671",
        'X-Aplitrak-Responding-Board-Name' => "Macildowie New",
        "X-Aplitrak-Original-From-Address" => @user.email,
        'X-Aplitrak-Original-Consultant' => @job.job["contact_name"],
        'X-Aplitrak-Original-Send_to_email' => @job.job["application_email"],
        'X-Aplitrak-Original-Ref' => @job.job["job_reference"],
        'X-Aplitrak-Original-Jobtitle' => @job.job["job_title"],
        'X-Aplitrak-Original-Subject' => "#{@job.job_type}/#{@job.job["job_title"]}/#{@job.job["job_reference"]}/Macildowie New/5671/#{@job.job["contact_name"]}/#{@job.disciplines.last["name"]}",
        'X-Aplitrak-Company' => "macildowie",
        'X-Aplitrak-User-Id' => @user.user_id.to_s,
        'X-Aplitrak-Time-Recived' => Time.now.to_formatted_s(:long),
        'X-Aplitrak-Job-Type' => @job.job_type,
        'X-Aplitrak-Salary_form' => @job.job["salary_low"],
        'X-Aplitrak-Itris_discipline' => CGI.unescapeHTML(@job.disciplines.last["reference"])
      }
    end
    create_log(@user, nil, 'email_data', nil, { headers: @headers }.to_s, nil, false, true)
  end

  private

  def discipline_of_interest
    if @user.registration_answers["sector-of-interest"].present?
      sector_of_interest = @user.registration_answers["sector-of-interest"]
      soi = sector_of_interest
      soi = "Finance" if sector_of_interest == 'Accountancy & Finance'
      soi = "Clerical - Non-Finance" if sector_of_interest == 'Commercial & Clerical'
      soi = "HR - Human Resources" if sector_of_interest == 'HR - Human Resources'
      soi = "HR - L&D & Training" if sector_of_interest == 'HR - L&D & Training'
      soi = "HR - Recruitment, Talent & Resourcing" if sector_of_interest == 'HR - Recruitment, Talent & Resourcing'
      soi = "S&M - Marketing" if sector_of_interest == 'Marketing'
      soi = "S&M - Sales" if sector_of_interest == 'Sales'
      soi = "Proc - Supply Chain" if sector_of_interest == 'Supply Chain'
      soi = "Proc - Warehouse and Logistics" if sector_of_interest == 'Warehouse and Logistics'
      soi = "Proc - Procurement" if sector_of_interest == 'Procurement'
      soi = "PRC - Experienced" if sector_of_interest == 'Work for Macildowie - Experienced'
      soi = "PRC - Trainee" if sector_of_interest == 'Work for Macildowie - Trainee'
      return soi
    else
      " "
    end
  end

  def salary_choice
    if @user.registration_answers["salary"].present?
      salary = @user.registration_answers["salary"]
      s = salary
      s = "15000" if salary == 'Under £15k'
      s = "17500" if salary == '£15 - 20k'
      s = "20000" if salary == '£20 - 30k'
      s = "30000" if salary == '£30 - 40k'
      s = "40000" if salary == '£40 - 50k'
      s = "50000" if salary == '£50 - 60k'
      s = "60000" if salary == '£60 - 70k'
      s = "70000" if salary == '£70 - 80k'
      s = "80000" if salary == '£80k plus'
      return s
    else
      " "
    end
  end

  def job_type
    if @user.registration_answers["job-type"].present?
      jtype = @user.registration_answers["job-type"]
      t = jtype
      t = "T" if jtype == 'Temp. Jobs'
      t = "P" if jtype == 'Permanent Jobs'
      t = "C" if jtype == 'Contract Jobs'
      return t
    else
      " "
    end
  end

  def legacy_user_type
    if params[:user][:user_group_name].present?
      return params[:user][:user_group_name]
    else
      return params[:user][:user_type]
    end
  end
end