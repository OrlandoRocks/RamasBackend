# frozen_string_literal: true

# KYC document uploads for Client (customer) records via Active Storage.
#
# Exactly three attachments per client:
#   - ine_document              — INE / government ID
#   - tax_document              — comprobante fiscal
#   - proof_of_address_document — comprobante de domicilio
module ClientDocumentAttachments
  extend ActiveSupport::Concern

  DOCUMENT_ATTACHMENTS = %i[
    ine_document
    tax_document
    proof_of_address_document
  ].freeze

  DOCUMENT_TYPES = {
    "ine" => :ine_document,
    "tax_document" => :tax_document,
    "proof_of_address" => :proof_of_address_document
  }.freeze

  ALLOWED_CONTENT_TYPES = %w[application/pdf image/jpeg image/png].freeze
  MAX_FILE_SIZE = 10.megabytes

  VERIFICATION_STATUSES = %w[pending approved rejected].freeze

  included do
    has_one_attached :ine_document
    has_one_attached :tax_document
    has_one_attached :proof_of_address_document

    attr_accessor :validate_documents

    validate :validate_required_documents, if: :validate_documents?
    validate :validate_document_file_constraints
  end

  def validate_documents?
    ActiveModel::Type::Boolean.new.cast(validate_documents)
  end

  def document_attachment_for(type)
    name = DOCUMENT_TYPES.fetch(type.to_s)
    public_send(name)
  end

  private

  def validate_required_documents
    DOCUMENT_ATTACHMENTS.each do |attachment_name|
      attachment = public_send(attachment_name)
      next if attachment.attached?

      errors.add(attachment_name, "must be attached")
    end
  end

  def validate_document_file_constraints
    DOCUMENT_ATTACHMENTS.each do |attachment_name|
      attachment = public_send(attachment_name)
      next unless attachment.attached?

      validate_blob!(attachment_name, attachment.blob)
    end
  end

  def validate_blob!(attachment_name, blob)
    unless ALLOWED_CONTENT_TYPES.include?(blob.content_type)
      errors.add(attachment_name, "must be a PDF, JPG, or PNG file")
    end

    return unless blob.byte_size > MAX_FILE_SIZE

    errors.add(attachment_name, "must be smaller than #{MAX_FILE_SIZE / 1.megabyte} MB")
  end
end
