# frozen_string_literal: true

# Handles Clients actions
class ClientsController < ApplicationController
  before_action :set_client, only: %i[show update destroy]

  # GET /clients
  # @return [void]
  def index
    @clients = Client.all
    render json: @clients
  end

  # GET /clients/1
  # @return [void]
  def show
    render json: @client
  end

  # POST /clients
  # @return [void]
  def create
    @client = Client.new(client_params)

    if @client.save
      render json: @client, status: :created
    else
      render json: @client.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clients/1
  # @return [void]
  def update
    if @client.update(client_params)
      render json: @client
    else
      render json: @client.errors, status: :unprocessable_entity
    end
  end

  # DELETE /clients/1
  # @return [void]
  def destroy
    @client.destroy
    render json: { message: "Client was successfully destroyed." }, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # @return [void]
  def set_client
    @client = Client.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  # @return [void]
  def client_params
    params.require(:client).permit(:code, :full_name, :identification_card, :rfc, :address, :colony,
                                   :zip_code, :phone_number, :city, :state, :country, :assignee, :email, :birthday,
                                   :nationality, :civil_status, :spouse, :economic_dependants, :home_owner, :occupation,
                                   :company, :company_address, :company_phone, :monthly_income, :monthly_expenses,
                                   :comments, :image)
  end
end
