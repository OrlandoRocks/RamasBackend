# frozen_string_literal: true

# serializer for payment model
class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :contract_id, :amount, :payment_date, :payment_type, :comments, :image_url, :client_name,
             :payment_status_name, :land_code, :land_address, :residential_name, :status


  def payment_status_name
    raw_status = object.attributes_before_type_cast["status"]
    Payment.status_label(raw_status)
  end

  def client_name
    client = object.contract.client
    "#{client.full_name} > #{Payment.format_phone(client.phone_number)}"
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
