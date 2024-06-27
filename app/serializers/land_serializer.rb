# frozen_string_literal: true

# serializer for land model
class LandSerializer < ActiveModel::Serializer
  attributes :id, :land_code, :address, :block, :size, :price, :house_number, :residential_name, :residential_id
  
  def residential_name
    object.residential.name.to_s
  end

  belongs_to :residential
end
