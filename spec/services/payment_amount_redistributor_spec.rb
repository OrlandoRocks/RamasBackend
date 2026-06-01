# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentAmountRedistributor do
  let(:land) { create(:land, price: 3000) }
  let(:contract) { create(:contract, land: land) }

  def create_payment(attrs)
    Payment.create!(
      {
        contract: contract,
        amount: 1000,
        payment_date: Date.current,
        payment_type: "Efectivo",
        status: "Pendiente"
      }.merge(attrs)
    )
  end

  def schedule_sum
    contract.payments.reload.sum(:amount).to_d
  end

  describe "#apply_delta!" do
    it "subtracts the increase from the last pending installment" do
      create_payment(amount: 1000, payment_date: 1.month.ago)
      second = create_payment(amount: 1000, payment_date: Date.current)
      edited = create_payment(amount: 1000, payment_date: 2.months.from_now)
      total_before = schedule_sum
      edited.update_without_redistribution!(amount: 1100)

      described_class.new(edited).apply_delta!(100)

      expect(second.reload.amount).to eq(900)
      expect(schedule_sum).to eq(total_before)
    end

    it "spreads a large increase across multiple pending installments down to zero" do
      first = create_payment(amount: 500, payment_date: 1.month.ago)
      second = create_payment(amount: 300, payment_date: Date.current)
      edited = create_payment(amount: 1000, payment_date: 2.months.from_now)
      total_before = schedule_sum
      edited.update_without_redistribution!(amount: 1600)

      described_class.new(edited).apply_delta!(600)

      expect(first.reload.amount.to_d).to eq(200.to_d)
      expect(second.reload.amount.to_d).to eq(0.to_d)
      expect(schedule_sum).to eq(total_before)
    end

    it "raises when increase cannot be fully absorbed" do
      first = create_payment(amount: 0, payment_date: 1.month.ago)
      create_payment(amount: 0, payment_date: Date.current)
      edited = create_payment(amount: 1000, payment_date: 2.months.from_now)
      edited.update_without_redistribution!(amount: 1500)

      expect {
        described_class.new(edited).apply_delta!(500)
      }.to raise_error(PaymentAmountRedistributor::UnabsorbedDeltaError)

      expect(first.reload.amount.to_d).to eq(0.to_d)
    end

    it "adds a decrease starting from the last pending installment" do
      create_payment(amount: 1000, payment_date: 1.month.ago)
      second = create_payment(amount: 1000, payment_date: Date.current)
      edited = create_payment(amount: 1000, payment_date: 2.months.from_now)
      total_before = schedule_sum
      edited.update_without_redistribution!(amount: 850)

      described_class.new(edited).apply_delta!(-150)

      expect(second.reload.amount).to eq(1150)
      expect(schedule_sum).to eq(total_before)
    end

    it "does not change paid or non-pending installments" do
      paid = create_payment(amount: 1000, payment_date: 1.month.ago, status: "Pagado")
      cancelled = create_payment(amount: 500, payment_date: 2.weeks.ago, status: "Cancelado")
      pending = create_payment(amount: 1000, payment_date: Date.current)
      edited = create_payment(amount: 1000, payment_date: 2.months.from_now)
      edited.update_without_redistribution!(amount: 1200)

      described_class.new(edited).apply_delta!(200)

      expect(paid.reload.amount).to eq(1000)
      expect(cancelled.reload.amount).to eq(500)
      expect(pending.reload.amount).to eq(800)
    end

    it "raises when no other pending installments exist" do
      only = create_payment(amount: 1000, payment_date: Date.current)
      only.update_without_redistribution!(amount: 1100)

      expect {
        described_class.new(only).apply_delta!(100)
      }.to raise_error(PaymentAmountRedistributor::UnabsorbedDeltaError)
    end
  end

  describe "model callback (rails console path)" do
    it "redistributes when amount is updated on the record" do
      create_payment(amount: 1000, payment_date: 1.month.ago)
      second = create_payment(amount: 1000, payment_date: Date.current)
      edited = create_payment(amount: 1000, payment_date: 2.months.from_now)
      total_before = schedule_sum

      edited.update!(amount: 1100)

      expect(second.reload.amount).to eq(900)
      expect(schedule_sum).to eq(total_before)
      expect(edited.last_redistribution_adjusted.size).to eq(1)
    end

    it "does not redistribute when only status changes" do
      pending = create_payment(amount: 1000, payment_date: Date.current)
      total_before = schedule_sum

      pending.update!(status: "Pagado")

      expect(schedule_sum).to eq(total_before)
      expect(pending.last_redistribution_adjusted).to be_nil
    end
  end
end
