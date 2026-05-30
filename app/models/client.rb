# frozen_string_literal: true

# Description: Client model (customer) with contracts, KYC documents, and portal users.
class Client < ApplicationRecord
  include ClientDocumentAttachments

  has_many :contracts, dependent: :nullify
  has_many :lands, through: :contracts
  has_many :payments, through: :lands

  has_many :residential_clients, dependent: :destroy
  has_many :residentials, through: :residential_clients

  has_many :users, through: :contracts

  validates :ine_verification_status,
            :tax_document_verification_status,
            :proof_of_address_verification_status,
            inclusion: { in: VERIFICATION_STATUSES }

  def documents_payload
    {
      ine: ClientDocumentSerializer.call(self, :ine_document, ine_verification_status),
      tax_document: ClientDocumentSerializer.call(self, :tax_document, tax_document_verification_status),
      proof_of_address: ClientDocumentSerializer.call(self, :proof_of_address_document, proof_of_address_verification_status)
    }
  end
end
