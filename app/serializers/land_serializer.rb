# frozen_string_literal: true

# serializer for land model
class LandSerializer < ActiveModel::Serializer
  attributes :id, :land_code, :address, :block, :size, :price, :house_number, :residential_name, :residential_id,
             :contract_id
  
  def residential_name
    object.residential.name.to_s
  end

  def contract_id
    object.contract&.id ? "yes" : "no"
  end


  belongs_to :residential
  has_one :contract
end
