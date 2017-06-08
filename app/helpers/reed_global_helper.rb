module ReedGlobalHelper

  def discipline_options
    @disciplines.map { |discipline| [discipline['name'], discipline['id']] }
  end

  def job_function_options(country)
    @job_functions.map { |job_function| [job_function['name'], job_function['id']] unless country.mapped_job_function_ids.include?(job_function['id']) }.compact
  end

  def select_js
    @reed_countries.map do |country|
      str = "$('#disciplines_#{country.id}').select2({placeholder: 'Pick specialism...'});"
      str += "$('#job_functions_#{country.id}').select2({placeholder: 'Pick sector...'});"
    end.join("\n")
  end
end