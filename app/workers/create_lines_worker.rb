class CreateLinesWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :default, :retry => false
  
  def perform(current_profile_id, file_id, tempfile_path)
    @data_import_file = DataImport::File.find file_id
    File.open(tempfile_path, "r") do |f|
      @data_import_file.create_lines(f)
    end
  end
end