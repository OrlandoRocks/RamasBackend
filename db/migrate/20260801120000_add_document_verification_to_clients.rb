# frozen_string_literal: true

class AddDocumentVerificationToClients < ActiveRecord::Migration[7.0]
  def change
    change_table :clients, bulk: true do |t|
      t.string :ine_verification_status, null: false, default: "pending"
      t.string :tax_document_verification_status, null: false, default: "pending"
      t.string :proof_of_address_verification_status, null: false, default: "pending"
    end
  end
end
