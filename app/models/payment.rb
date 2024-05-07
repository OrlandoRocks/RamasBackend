# frozen_string_literal: true

# Description: Payment model that belongs to a land and has one client through land.
class Payment < ApplicationRecord
  belongs_to :land

  has_one :client, through: :land
end
