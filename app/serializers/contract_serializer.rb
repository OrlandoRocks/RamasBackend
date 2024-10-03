# frozen_string_literal: true

# serializer for contract model
class ContractSerializer < ActiveModel::Serializer
  attributes :id, :client_id, :client_name, :land_id, :land_code, :contract_date, :type, :down_payment,
             :monthly_payment, :yearly_payment, :months, :penalty_interest, :extraordinary_payment,
             :total_price, :total_paid, :payments

  def client_name
    object.client.full_name.to_s
  end

  def land_code
    "#{object.land.residential.name} - #{object.land.land_code.to_s}"
  end

  def total_price
    object.land.price.to_s
  end

  def total_paid
    object.payments.where(status: Payment.payment_statuses["Pagado"]).sum(:amount).to_s
  end

  belongs_to :client
  belongs_to :land

  has_many :payments, serializer: PaymentSerializer
end
