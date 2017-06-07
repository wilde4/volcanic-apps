module ReedGlobalHelper

  def discipline_options
    @disciplines.map { |discipline| [discipline['name'], discipline['id']] }
  end

  def job_function_options
    @job_functions.map { |job_function| [job_function['name'], job_function['id']] }
  end
end