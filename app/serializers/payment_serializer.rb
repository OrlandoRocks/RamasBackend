# frozen_string_literal: true

# serializer for payment model
class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :amount, :payment_date, :payment_type, :comments, :image_url, :client_name, :payment_status_name,
             :land_code, :land_address, :residential_name, :status


  def payment_status_name
    object.class.payment_statuses.key(object.status.to_i)
  end

  def client_name
    "#{object.contract.client.full_name.to_s} > #{object.contract.client.phone_number.to_s.insert(3, '-').insert(7, '-')}"
  end

  def land_code
    object.contract.land.land_code.to_s
  end

  def land_address
    object.contract.land.address.to_s
  end

  def residential_name
    object.contract.land.residential.name.to_s
  end

  belongs_to :contract
end
