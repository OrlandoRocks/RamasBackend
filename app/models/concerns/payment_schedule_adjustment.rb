# frozen_string_literal: true

# Runs installment redistribution when amount changes (API, console, nested attributes).
module PaymentScheduleAdjustment
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_amount_redistribution, :last_redistribution_adjusted

    after_commit :redistribute_installments_after_amount_change, on: :update
  end

  class_methods do
    def adjustable_status_values
      [statuses["Pendiente"], "Pendiente", "pending", "0", 0].uniq
    end
  end

  def adjustable?
    self.class.adjustable_status_values.include?(attributes_before_type_cast["status"])
  end

  private

  def redistribute_installments_after_amount_change
    return if skip_amount_redistribution
    return if PaymentAmountRedistributor.redistributing?
    return unless saved_change_to_amount?

    old_amount, new_amount = saved_change_to_amount
    delta = new_amount.to_d - old_amount.to_d
    return if delta.zero?

    contract.with_schedule_lock do
      adjusted = PaymentAmountRedistributor.new(self).apply_delta!(delta)
      self.last_redistribution_adjusted = adjusted
    end
  end
end
