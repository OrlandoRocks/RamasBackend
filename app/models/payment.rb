# frozen_string_literal: true

# Description: Payment model that belongs to a land and has one client through land.
class Payment < ApplicationRecord
  belongs_to :contract


  has_one :client, through: :contract
  has_one :land, through: :contract

  enum payment_status: {
    Pendiente: 0,
    Pagado: 1,
    Fallo: 2,
    Regrezado: 3,
    Cancelado: 4
  }


  def as_json(options = {})
    super(options).merge(status_name: status_name)
  end

  def status_name
    Payment.payment_statuses.key(status)
  end
end
