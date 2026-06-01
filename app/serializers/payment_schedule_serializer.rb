# frozen_string_literal: true

# Lightweight payment JSON for contract schedule tables (no nested contract).
class PaymentScheduleSerializer < ActiveModel::Serializer
  attributes :id, :contract_id, :amount, :payment_date, :payment_type, :comments, :image_url, :status,
             :payment_status_name

  def payment_status_name
    raw_status = object.attributes_before_type_cast["status"]
    Payment.status_label(raw_status)
  end
end
