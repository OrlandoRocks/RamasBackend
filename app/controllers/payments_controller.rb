# frozen_string_literal: true

# Description: Controller for payments model
class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[show update destroy]

  def index
    @payments = policy_scope(Payment)
    authorize Payment

    render json: @payments, except: [:contract]
  end

  def show
    authorize @payment
    render json: @payment, serializer: PaymentSerializer, include_contract: true
  end

  def payment_statuses
    authorize Payment, :payment_statuses?
    render json: Payment.statuses
  end

  def create
    @payment = Payment.new(payment_params)
    authorize @payment
    if @payment.save
      render json: @payment, status: :created
    else
      render json: { errors: @payment.errors }, status: :unprocessable_entity
    end
  end

  def update
    authorize @payment

    begin
      @payment.contract.with_schedule_lock do
        if @payment.update(payment_params)
          adjusted = @payment.last_redistribution_adjusted || []
          response.headers["X-Adjusted-Payments-Count"] = adjusted.size.to_s if amount_param_present?
          render json: @payment.reload, serializer: PaymentSerializer, status: :ok
        else
          render json: { errors: @payment.errors }, status: :unprocessable_entity
        end
      end
    rescue PaymentAmountRedistributor::Error => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @payment
    @payment.destroy
    render json: { message: "Payment deleted" }, status: :ok
  end

  private

  def set_payment
    @payment = policy_scope(Payment).find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :payment_date, :payment_type, :comments, :image_url, :contract_id, :status)
  end

  def amount_param_present?
    return true if params.key?(:amount)

    payment = params[:payment]
    payment.is_a?(ActionController::Parameters) ? payment.key?(:amount) : payment.to_h.key?(:amount)
  end
end
