class ChangeMailchimpConditionRegistrationQuestionIdToReference < ActiveRecord::Migration
  def change
    rename_column :mail_chimp_conditions, :registration_question_id, :registration_question_reference
    change_column :mail_chimp_conditions, :registration_question_reference, :string
  end
end
