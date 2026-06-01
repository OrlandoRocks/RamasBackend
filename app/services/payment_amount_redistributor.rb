# frozen_string_literal: true

# When a payment amount changes, shift the difference across other pending
# installments so the contract schedule total stays fixed.
class PaymentAmountRedistributor
  class Error < StandardError; end
  class UnabsorbedDeltaError < Error; end
  class ScheduleTotalMismatchError < Error; end

  def self.redistributing?
    Thread.current[:payment_amount_redistributing] == true
  end

  def initialize(payment)
    @payment = payment
    @contract = payment.contract
  end

  # @param delta [BigDecimal] positive = edited payment increased; subtract from others
  # @return [Array<Payment>] rows that were updated (excluding the edited payment)
  def apply_delta!(delta)
    delta = delta.to_d
    return [] if delta.zero?

    others = other_adjustable_payments
    if others.empty?
      raise UnabsorbedDeltaError, "No pending installments available to balance this change" if delta.nonzero?

      return []
    end

    schedule_total_before = @contract.payments_sum

    Thread.current[:payment_amount_redistributing] = true
    updated =
      if delta.positive?
        subtract_from_others!(delta, others)
      else
        add_to_others!(-delta, others)
      end

    verify_schedule_total!(schedule_total_before, delta)
    updated
  ensure
    Thread.current[:payment_amount_redistributing] = false
  end

  private

  def other_adjustable_payments
    @contract.payments
              .where.not(id: @payment.id)
              .where(status: Payment.adjustable_status_values)
              .order(payment_date: :asc, id: :asc)
              .to_a
  end

  def subtract_from_others!(remaining_delta, others)
    updated, leftover = spread_change!(remaining_delta, others, mode: :subtract)
    raise UnabsorbedDeltaError, "Could not absorb full increase across pending installments" if leftover.positive?

    updated
  end

  def add_to_others!(amount, others)
    updated, leftover = spread_change!(amount, others, mode: :add)
    raise UnabsorbedDeltaError, "Could not distribute decrease across pending installments" if leftover.positive?

    updated
  end

  # Greedy from latest pending installment backward (same order for increase and decrease).
  def spread_change!(remaining, others, mode:)
    updated = []
    left = remaining.to_d

    others.reverse_each do |payment|
      break if left <= 0

      current = payment.amount.to_d
      change =
        if mode == :subtract
          next if current <= 0

          [left, current].min
        else
          left
        end

      new_amount = (mode == :subtract ? current - change : current + change).round(2)
      payment.update_without_redistribution!(amount: new_amount)
      updated << payment
      left -= change
    end

    [updated, left]
  end

  # Edited installment already reflects +delta; others move by -delta so contract sum stays at (before - delta).
  def verify_schedule_total!(schedule_total_before, delta)
    schedule_total_after = @contract.payments.reload.sum(:amount).to_d
    expected = schedule_total_before - delta
    return if schedule_total_after.round(2) == expected.round(2)

    raise ScheduleTotalMismatchError,
          "Payment schedule total is #{schedule_total_after}, expected #{expected}"
  end
end
