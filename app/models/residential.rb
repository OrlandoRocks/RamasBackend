# frozen_string_literal: true

# Description: Client model that has many contracts, lands, residentials, payments and users through contracts.
class Residential < ApplicationRecord
  belongs_to :user

  has_many :lands
  has_many :expenses
  has_many :payments, through: :lands
  has_many :clients, through: :lands
  has_many :contracts, through: :lands
end
