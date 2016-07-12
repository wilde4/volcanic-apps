xml.instruct!
xml.details do
  xml.candidatedetails do
    @user.each do |k,v|
      xml.tag!(k, v)
    end
    @user_profile.each do |k,v|
      xml.tag!(k, v)
    end
    @registration_answer_hash.each do |k,v|
      xml.tag!(k, v)
    end
  end
  xml.jobdetails do
    @job.each do |k,v|
      if k == 'job_description'
        xml.tag!(k) { xml.cdata!(v) }
      else
        xml.tag!(k, v)
      end
    end
    xml.source @source
    xml.applicationdate @applicationdate
  end
end
