class AddLegalDocumentsToArithonUsers < ActiveRecord::Migration
  def change
    add_column :arithon_users, :legal_documents, :text
  end
end
