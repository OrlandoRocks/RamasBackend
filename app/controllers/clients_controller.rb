# frozen_string_literal: true

# Handles Clients actions (customer records + KYC document uploads).
class ClientsController < ApplicationController
  before_action :set_client, only: %i[show update destroy]

  # GET /clients
  def index
    @clients = policy_scope(Client)
    authorize Client

    render json: @clients, each_serializer: ClientSerializer
  end

  # GET /clients/1
  def show
    authorize @client
    render json: @client, serializer: ClientSerializer
  end

  # POST /clients
  # Set client[require_documents]=true to enforce all three attachments on create.
  def create
    @client = Client.new(client_params)
    @client.validate_documents = require_documents?
    authorize @client

    if @client.save
      sync_residential_links!(@client)
      render json: @client, serializer: ClientSerializer, status: :created
    else
      render json: { errors: client_error_messages(@client) }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clients/1
  # Re-uploading any document resets that document's verification status to pending.
  def update
    authorize @client

    @client.assign_attributes(client_params)
    @client.validate_documents = require_documents?
    block_client_replacement_of_approved_documents!(@client)
    reset_verification_statuses_for_changed_documents(@client)

    if @client.errors.any?
      return render json: { errors: client_error_messages(@client) }, status: :unprocessable_entity
    end

    if @client.save
      sync_residential_links!(@client) unless current_user&.client?
      render json: @client, serializer: ClientSerializer
    else
      render json: { errors: client_error_messages(@client) }, status: :unprocessable_entity
    end
  end

  # DELETE /clients/1
  def destroy
    authorize @client
    @client.destroy
    render json: { message: "Client was successfully destroyed." }, status: :ok
  end

  private

  def set_client
    @client = policy_scope(Client).find(params[:id])
  end

  STAFF_CLIENT_ATTRS = [
    :code, :full_name, :identification_card, :rfc, :address, :colony,
    :zip_code, :phone_number, :city, :state, :country, :assignee, :email, :birthday,
    :nationality, :civil_status, :spouse, :economic_dependants, :home_owner, :occupation,
    :company, :company_address, :company_phone, :monthly_income, :monthly_expenses,
    :comments, :image,
    :ine_verification_status, :tax_document_verification_status, :proof_of_address_verification_status,
    :ine_document, :tax_document, :proof_of_address_document,
    { residential_ids: [] }
  ].freeze

  CLIENT_SELF_ATTRS = [
    :full_name, :identification_card, :rfc, :address, :colony,
    :zip_code, :phone_number, :city, :state, :country, :email, :birthday,
    :nationality, :civil_status, :spouse, :economic_dependants, :home_owner, :occupation,
    :company, :company_address, :company_phone, :monthly_income, :monthly_expenses,
    :comments,
    :ine_document, :tax_document, :proof_of_address_document
  ].freeze

  def client_params
    attrs = current_user&.client? ? CLIENT_SELF_ATTRS : STAFF_CLIENT_ATTRS
    params.require(:client).permit(*attrs)
  end

  def sync_residential_links!(client)
    ids = params.dig(:client, :residential_ids)
    return if ids.nil?

    client.residential_ids = ids.reject(&:blank?).map(&:to_i)
  end

  def require_documents?
    ActiveModel::Type::Boolean.new.cast(params.dig(:client, :require_documents))
  end

  APPROVED_DOCUMENT_GUARD = {
    ine_document: :ine_verification_status,
    tax_document: :tax_document_verification_status,
    proof_of_address_document: :proof_of_address_verification_status
  }.freeze

  def block_client_replacement_of_approved_documents!(client)
    return unless current_user&.client?

    client.attachment_changes.each_key do |attachment_name|
      status_column = APPROVED_DOCUMENT_GUARD[attachment_name.to_sym]
      next unless status_column

      next unless client.public_send(status_column) == "approved"

      client.errors.add(attachment_name, "no puede modificarse después de ser aprobado")
    end
  end

  def reset_verification_statuses_for_changed_documents(client)
    client.attachment_changes.each_key do |attachment_name|
      case attachment_name.to_sym
      when :ine_document
        client.ine_verification_status = "pending"
      when :tax_document
        client.tax_document_verification_status = "pending"
      when :proof_of_address_document
        client.proof_of_address_verification_status = "pending"
      end
    end
  end

  def client_error_messages(client)
    client.errors.full_messages
  end
end
