# frozen_string_literal: true

# serializer for land model
class LandSerializer < ActiveModel::Serializer
  attributes :id, :land_code, :address, :block, :size, :price, :house_number, :residential_name, :residential_id,
             :client_name, :client_id, :contract_id
  
  def residential_name
    object.residential.name.to_s
  end

  def client_name
    object.client&.full_name.to_s
  end

  def client_id
    object.client&.id
  end

  def contract_id
    object.contract&.id
  end

  belongs_to :residential
  has_one :contract
end
