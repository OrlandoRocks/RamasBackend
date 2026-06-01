# frozen_string_literal: true

module ContractPaymentSchedule
  extend ActiveSupport::Concern

  def schedule_total_amount
    land&.price.to_d
  end

  def payments_sum
    payments.sum(:amount).to_d
  end

  def schedule_balanced?
    return true if schedule_total_amount <= 0

    payments_sum.round(2) == schedule_total_amount.round(2)
  end

  def with_schedule_lock
    lock!
    yield
  end
end
