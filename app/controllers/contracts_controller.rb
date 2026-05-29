# frozen_string_literal: true

# Description: Controller for contracts model
class ContractsController < ApplicationController
  before_action :set_contract, only: %i[show update destroy]

  # GET /contracts
  # @return [void]
  def index
    @contracts = policy_scope(Contract).includes(:client, :payments, land: :residential)
    authorize Contract

    render json: @contracts, each_serializer: ContractIndexSerializer
  end

  # GET /contracts/1
  # @return [void]
  def show
    authorize @contract
    render json: @contract, serializer: ContractSerializer
  end

  # GET /contracts/1/payments
  # @return [void]
  def payments
    @contract = policy_scope(Contract).find(params[:id])
    authorize @contract, :payments?

    @payments = @contract.payments.order(payment_date: :asc, id: :asc)
    render json: @payments, each_serializer: PaymentScheduleSerializer
  end

  # POST /contracts
  # @return [void]
  def create
    @contract = Contract.new(contract_params)

    authorize @contract

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
    authorize @contract

    @contract.with_schedule_lock do
      if @contract.update(contract_params)
        render json: @contract
      else
        render json: @contract.errors, status: :unprocessable_entity
      end
    end
  rescue PaymentAmountRedistributor::Error => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  # DELETE /contracts/1
  # @return [void]
  def destroy
    authorize @contract
    @contract.destroy
    render json: { message: "Contract was successfully destroyed." }, status: :ok
  end

  def user_contracts
    @contracts = Contract.where(client_id: params[:id])
    render json: @contracts, each_serializer: ContractSerializer, adapter: :json_api, status: :ok
  end

  def current_month_payments
    @payments = Contract.current_month_payments(current_user&.id)
    render json: @payments
  end

  def lands_sold
    @lands = Contract.lands_sold(current_user&.id)
    render json: @lands
  end

  def total_paid
    @total_paid = Contract.total_paid(current_user&.id)
    render json: @total_paid
  end

  def preview_template
    @contract = Contract.find(params[:id])
    @seller = @contract.land.residential.user
    @buyer = @contract.client
    @land = @contract.land
    @precio_letras = @land.price.to_i

    latest_version = @contract.contract_versions&.order(created_at: :desc)&.first

    if latest_version
      html_content = latest_version.html_content
    else
      html_content = ActionController::Base.render(
        template: 'pdf_templates/contract',
        layout: false,
        assigns: {
          contract: @contract,
          seller: @seller,
          buyer: @buyer,
          land: @land,
          precio_letras: @precio_letras
        }
      )
    end

    render json: { html: html_content }
  end

  def generate_custom_pdf
    custom_html = params[:html_content]

    pdf_binary = WickedPdf.new.pdf_from_string(
      custom_html,
      page_size: 'Letter',
      margin: { top: 20, bottom: 20, left: 20, right: 20 }
    )

    puts "pdf_binarypdf_binarypdf_binarypdf_binarypdf_binary"
    puts "pdf_binarypdf_binarypdf_binarypdf_binarypdf_binary"
    puts "pdf_binarypdf_binarypdf_binarypdf_binarypdf_binary"
    puts pdf_binary

    send_data pdf_binary,
              filename: "Contrato_Compraventa.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def save_version
    @contract = Contract.find(params[:id])

    # Creamos la versión con el HTML enviado desde Vue
    @version = @contract.contract_versions.new(
      html_content: params[:html_content],
      version_number: @contract.contract_versions.count + 1
    )

    if @version.save
      render json: @version, status: :created
    else
      render json: { errors: @version.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # @return [void]
  def set_contract
    @contract = policy_scope(Contract).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  # @return [void]
  def contract_params
    params.require(:contract).permit(:contract_date, :contract_type, :down_payment, :monthly_payment,
                                     :yearly_payment, :months, :penalty_interest,
                                     :extraordinary_payment, :client_id, :land_id,
                                     payments_attributes: %i[id amount payment_date payment_type
                                                             comments image_url status _destroy])
  end
end
