# frozen_string_literal: true

# Description: Contract model that belongs to a client and a land and has many users.
class Contract < ApplicationRecord
  belongs_to :client
  belongs_to :land

  has_many :payments, dependent: :destroy
  has_many :contract_versions, dependent: :destroy

  accepts_nested_attributes_for :payments


  def self.current_month_payments client_id
    Payment.joins(contract: :client)
           .where(contracts: { client_id: client_id })
           .where(status: Payment.payment_statuses["Pagado"], payment_date: Date.current.end_of_month)
           .sum(:amount)
  end

  def self.lands_sold client_id
    self.where(client_id: client_id).pluck(:land_id).count
  end

  def self.total_paid client_id
    Payment.joins(contract: :client)
           .where(contracts: { client_id: client_id })
           .where(status: Payment.payment_statuses["Pagado"])
           .sum(:amount)
  end
end
