# frozen_string_literal: true

# Description: Payment model that belongs to a land and has one client through land.
class Payment < ApplicationRecord
  belongs_to :contract


  has_one :client, through: :contract
  has_one :land, through: :contract

  enum :status, {
    Pendiente: "Pendiente",
    Pagado: "Pagado",
    Fallo: "Fallo",
    Regrezado: "Regrezado",
    Cancelado: "Cancelado"
  }, default: "Pendiente"

  LEGACY_STATUS_ALIASES = {
    "pending" => "Pendiente",
    "paid" => "Pagado",
    "0" => "Pendiente",
    "1" => "Pagado",
    "2" => "Fallo",
    "3" => "Regrezado",
    "4" => "Cancelado"
  }.freeze

  def self.coerce_status(raw_status)
    return nil if raw_status.nil? || raw_status == ""

    normalized = raw_status.to_s
    return normalized if statuses.value?(normalized)

    LEGACY_STATUS_ALIASES[normalized] || LEGACY_STATUS_ALIASES[normalized.downcase]
  end

  def self.status_label(raw_status)
    coerce_status(raw_status) || "Pendiente"
  end

  def status=(value)
    coerced = self.class.coerce_status(value)
    super(coerced) if coerced.present?
  end

  def self.paid_status_values
    [statuses["Pagado"], "Pagado", "1", 1].uniq
  end

  def self.format_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")
    return phone.to_s if digits.length < 10

    "#{digits[0, 3]}-#{digits[3, 3]}-#{digits[6..]}"
  end

  def as_json(options = {})
    super(options).merge(status_name: status_name)
  end

  def status_name
    self.class.status_label(attributes_before_type_cast["status"])
  end
end
