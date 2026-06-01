# frozen_string_literal: true

# Description: Contract model that belongs to a client and a land and has many users.
class Contract < ApplicationRecord
  include ContractPaymentSchedule

  belongs_to :client
  belongs_to :land

  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :payments

  after_save :link_client_to_residential

  private

  def link_client_to_residential
    residential_id = land&.residential_id
    return unless residential_id && client_id

    ResidentialClient.link!(client_id: client_id, residential_id: residential_id)
  end
end
