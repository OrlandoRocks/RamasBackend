# frozen_string_literal: true

# Builds JSON metadata for a single Active Storage attachment on Client.
class ClientDocumentSerializer
  def self.call(client, attachment_name, verification_status)
    attachment = client.public_send(attachment_name)

    unless attachment.attached?
      return {
        attached: false,
        verification_status: verification_status
      }
    end

    blob = attachment.blob
    {
      attached: true,
      filename: blob.filename.to_s,
      content_type: blob.content_type,
      byte_size: blob.byte_size,
      verification_status: verification_status,
      url: document_url(client, attachment_name)
    }
  end

  def self.document_url(client, attachment_name)
    type = Client::DOCUMENT_TYPES.key(attachment_name)
    "/clients/#{client.id}/documents/#{type}"
  end
end
