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

  # def update
  #   expected_amount = @payment.amount
  #
  #   if @payment.update(payment_params)
  #     actual_amount = params[:payment][:amount].to_f
  #
  #     if @payment.status.to_i == Payment.payment_statuses["Pagado"] && actual_amount != expected_amount
  #       recalculate_future_payments(expected_amount, actual_amount)
  #     end
  #
  #     render json: @payment, status: :ok
  #   else
  #     render json: { errors: @payment.errors }, status: :unprocessable_entity
  #   end
  # end
  #
  # def update_amount(new_amount)
  #   if new_amount > @payment.amount
  #     # Adjust the oldest payment date's amount
  #     oldest_payment =
  #       @payment.contract.payments.where.not(status: Payment.payment_statuses["Pagado"]).order(payment_date: :asc).last
  #     oldest_payment.update(amount: oldest_payment.amount + (new_amount - @payment.amount))
  #   elsif new_amount < @payment.amount
  #     # Adjust the oldest payment date's amount
  #     oldest_payment =
  #       @payment.contract.payments.where.not(status: Payment.payment_statuses["Pagado"]).order(payment_date: :asc).last
  #     oldest_payment.update(amount: oldest_payment.amount - (@payment.amount - new_amount))
  #   end
  #
  #   if oldest_payment.amount <= 0
  #     # Change the payment status to paid
  #     oldest_payment.update(status: Payment.payment_statuses["Pagado"])
  #   end
  # end

  def destroy
    authorize @payment
    @payment.destroy
    render json: { message: "Payment deleted" }, status: :ok
  end

  private

  def set_payment
    @payment = policy_scope(Payment).find(params[:id])
  end

  def recalculate_future_payments(expected_amount, actual_amount)
    puts "actual_amount", actual_amount
    puts "expected_amount", expected_amount
    difference = (actual_amount - expected_amount).to_d

    puts "difference", difference

    pending_payments = @payment.contract.payments
                               .where(status: "pending")
                               .where.not(id: @payment.id)
                               .order(payment_date: :asc)

    puts "pending_payments", pending_payments.count

    return if pending_payments.empty?

    # adjustment_per_payment = difference / pending_payments.count
    # puts "adjustment_per_payment", adjustment_per_payment

    total_pending = pending_payments.sum(:amount).to_d

    Payment.transaction do
      if difference >= total_pending
        pending_payments.each do |pending_payment|
          pending_payment.update!(amount: 0, status: Payment.payment_statuses["Cancelado"])
        end
      else
        remaining_balance = total_pending - difference
        new_monthly_amount = (remaining_balance / pending_payments.count).round(2)

        pending_payments.each_with_index do |pending_payment, index|
          if index == pending_payments.count - 1
            last_payment_amount = remaining_balance - (new_monthly_amount * (pending_payments.count - 1))
            pending_payment.update!(amount: last_payment_amount)
          else
            pending_payment.update!(amount: new_monthly_amount)
          end
        end
      end
    end
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
