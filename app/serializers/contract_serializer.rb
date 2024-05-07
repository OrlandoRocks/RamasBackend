# frozen_string_literal: true

# serializer for contract model
class ContractSerializer < ActiveModel::Serializer
  attributes :id, :contract_date, :type, :down_payment, :monthly_payment,
             :yearly_payment, :months, :penalty_interest, :extraordinary_payment

  belongs_to :client
  belongs_to :land
end
