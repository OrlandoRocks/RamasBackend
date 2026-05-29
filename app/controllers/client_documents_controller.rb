# frozen_string_literal: true

# Authenticated download proxy for client KYC blobs (never expose storage paths directly).
class ClientDocumentsController < ApplicationController
  before_action :set_client

  # GET /clients/:id/documents/:document_type
  # document_type: ine | tax_document | proof_of_address
  def show
    authorize @client, :show?

    attachment = @client.document_attachment_for(params[:document_type])
    unless attachment.attached?
      return render json: { error: "Document not found" }, status: :not_found
    end

    redirect_to rails_blob_url(attachment, disposition: params[:disposition] || "inline"), allow_other_host: true
  end

  private

  def set_client
    @client = policy_scope(Client).find(params[:id])
  end
end
