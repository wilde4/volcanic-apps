class ReedCountry < ActiveRecord::Base
  has_many :mappings, class_name: 'ReedMapping', dependent: :destroy

  validates :dataset_id, :country_reference, :name, presence: true

  def mappings_by_discipline(disciplines)
    mappings_hash = {}
    mappings.each do |mapping|
      discipline = disciplines.find { |discipline| discipline['id'] == mapping.discipline_id }
      name = discipline.present? ? discipline['name'] : 'Unknown Discipline'
      mappings_hash[name] ||= []
      mappings_hash[name] << mapping
    end
    mappings_hash
  end

  def mapped_job_function_ids
    mappings.map(&:job_function_id)
  end

end