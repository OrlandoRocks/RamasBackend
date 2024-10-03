#frozen_string_literal: true

# Description: Controller for contracts model
class ContractsController < ApplicationController
  before_action :set_contract, only: %i[show update destroy]

  # GET /contracts
  # @return [void]
  def index
    @contracts = Contract.all
    render json: @contracts, except: [:payments]
  end

  # GET /contracts/1
  # @return [void]
  def show
    render json: @contract
  end

  # GET /contracts/1/payments
  # @return [void]
  def payments
    @contract = Contract.find(params[:contract_id])
    @payments = @contract.payments
    render json: @payments
  end

  # POST /contracts
  # @return [void]
  def create
    @contract = Contract.new(contract_params)

    ActiveRecord::Base.transaction do
      if @contract.save
        render json: @contract, status: :created
      else
        render json: @contract.errors, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  # PATCH/PUT /contracts/1
  # @return [void]
  def update
    if @contract.update(contract_params)
      render json: @contract
    else
      render json: @contract.errors, status: :unprocessable_entity
    end
  end

  # DELETE /contracts/1
  # @return [void]
  def destroy
    @contract.destroy
    render json: { message: "Contract was successfully destroyed." }, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # @return [void]
  def set_contract
    @contract = Contract.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  # @return [void]
  def contract_params
    params.require(:contract).permit(:contract_date, :type, :down_payment, :monthly_payment,
                                     :yearly_payment, :months, :penalty_interest,
                                     :extraordinary_payment, :client_id, :land_id,
                                     payments_attributes: %i[id amount payment_date payment_type
                                                             comments image_url status _destroy])
  end
end
