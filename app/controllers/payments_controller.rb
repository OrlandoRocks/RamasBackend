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
    if @payment.update(payment_params)
      update_amount(params[:amount]) if params[:amount]
      render json: @payment, status: :ok
    else
      render json: { errors: @payment.errors }, status: :unprocessable_entity
    end
  end

  def update_amount(new_amount)
    return if new_amount.blank?

    new_amount = new_amount.to_d
    pending_scope = @payment.contract.payments.where.not(status: Payment.paid_status_values).order(payment_date: :asc)
    oldest_payment = pending_scope.last
    return unless oldest_payment

    if new_amount > @payment.amount
      oldest_payment.update(amount: oldest_payment.amount + (new_amount - @payment.amount))
    elsif new_amount < @payment.amount
      oldest_payment.update(amount: oldest_payment.amount - (@payment.amount - new_amount))
    end

    oldest_payment.reload
    return unless oldest_payment.amount <= 0

    oldest_payment.update(status: "Pagado")
  end

  def destroy
    authorize @payment
    @payment.destroy
    render json: { message: 'Payment deleted' }, status: :ok
  end

  private

  def set_payment
    @payment = policy_scope(Payment).find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :payment_date, :payment_type, :comments, :image_url, :contract_id, :status)
  end
end
