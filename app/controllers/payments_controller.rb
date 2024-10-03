# frozen_string_literal: true

# Description: Controller for payments model
class PaymentsController < ApplicationController
  before_action :set_payment, only: %i[show update destroy]

  def index
    @payments = Payment.all
    render json: @payments, except: [:contract]
  end

  def show
    render json: Payment.find(params[:id]), serializer: PaymentSerializer, include_contract: true
  end

  def payment_statuses
    render json: Payment.payment_statuses
  end

  def create
    @payment = Payment.new(payment_params)
    if @payment.save
      render json: @payment, status: :created
    else
      render json: { errors: @payment.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @payment.update(payment_params)
      update_amount(params[:amount]) if params[:amount]
      render json: @payment, status: :ok
    else
      render json: { errors: @payment.errors }, status: :unprocessable_entity
    end
  end

  def update_amount(new_amount)
    if new_amount > @payment.amount
      # Adjust the oldest payment date's amount
      oldest_payment =
        @payment.contract.payments.where.not(status: Payment.payment_statuses["Pagado"]).order(payment_date: :asc).last
      oldest_payment.update(amount: oldest_payment.amount + (new_amount - @payment.amount))
    elsif new_amount < @payment.amount
      # Adjust the oldest payment date's amount
      oldest_payment =
        @payment.contract.payments.where.not(status: Payment.payment_statuses["Pagado"]).order(payment_date: :asc).last
      oldest_payment.update(amount: oldest_payment.amount - (@payment.amount - new_amount))
    end

    if oldest_payment.amount <= 0
      # Change the payment status to paid
      oldest_payment.update(status: Payment.payment_statuses["Pagado"])
    end
  end

  def destroy
    @payment.destroy
    render json: { message: 'Payment deleted' }, status: :ok
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :payment_date, :payment_type, :comments, :image_url, :contract_id, :status)
  end
end
