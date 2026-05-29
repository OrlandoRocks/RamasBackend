# frozen_string_literal: true

# Dashboard aggregates for the frontend home screen
class DashboardController < ApplicationController
  # GET /dashboard/pending_payments
  # Optional query param: residential_id
  def pending_payments
    authorize :dashboard, :pending_payments?

    cutoff = Date.current.end_of_month
    scope = policy_scope(Payment).includes(contract: { client: [], land: :residential })
                                     .where(status: Payment.statuses[:Pendiente])
                                     .where(payment_date: ..cutoff)
                                     .order(:payment_date)

    if params[:residential_id].present?
      scope = scope.joins(contract: :land).where(lands: { residential_id: params[:residential_id] })
    end

    render json: scope.map { |payment| pending_payment_row(payment) }
  end

  private

  def pending_payment_row(payment)
    contract = payment.contract
    land = contract.land
    client = contract.client
    contract_payments = contract.payments
    total = contract_payments.size
    paid = contract_payments.where(status: Payment.paid_status_values).count
    progress = total.positive? ? ((paid.to_f / total) * 100).round : 0
    on_time = payment.payment_date.year == Date.current.year &&
              payment.payment_date.month == Date.current.month

    {
      payment_id: payment.id,
      payment_date: payment.payment_date.iso8601,
      land_id: land.id,
      residential_id: land.residential_id,
      client_name: client.full_name.to_s,
      email: client.email.to_s,
      phone: Payment.format_phone(client.phone_number),
      progress: progress,
      timing_status: on_time ? "A tiempo" : "Retrasado",
      land_code: land.land_code.to_s,
      residential_name: land.residential.name.to_s,
      land_address: land.address.to_s
    }
  end
end
