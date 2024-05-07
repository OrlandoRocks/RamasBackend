# frozen_string_literal: true

# serializer for payment model
class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :amount, :payment_date, :payment_type, :comments, :image_url, :status

  belongs_to :land
end
