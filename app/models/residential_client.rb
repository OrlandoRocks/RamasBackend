# frozen_string_literal: true

class ResidentialClient < ApplicationRecord
  belongs_to :client
  belongs_to :residential

  validates :client_id, uniqueness: { scope: :residential_id }

  # Ensures CRM visibility for staff assigned to the development.
  def self.link!(client_id:, residential_id:)
    return if client_id.blank? || residential_id.blank?

    find_or_create_by!(client_id: client_id, residential_id: residential_id)
  end
end
