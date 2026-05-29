# frozen_string_literal: true

# Lightweight serializer for GET /contracts (no nested payments).
class ContractIndexSerializer < ActiveModel::Serializer
  attributes :id, :client_id, :client_name, :land_id, :land_code, :land_address,
             :contract_date, :contract_type, :down_payment, :monthly_payment,
             :yearly_payment, :months, :penalty_interest, :extraordinary_payment,
             :total_price, :total_paid

  def client_name
    object.client.full_name.to_s
  end

  def land_code
    return "" unless object.land

    residential = object.land.residential&.name
    code = object.land.land_code
    residential.present? ? "#{residential} - #{code}" : code.to_s
  end

  def land_address
    object.land&.address.to_s
  end

  def total_price
    object.land&.price&.to_s
  end

  def total_paid
    object.payments.where(status: Payment.paid_status_values).sum(:amount).to_s
  end
end
