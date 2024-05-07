# frozen_string_literal: true

# serializer for land model
class LandSerializer < ActiveModel::Serializer
  attributes :id, :type, :address, :block, :size, :price, :house_number

  belongs_to :residential
end
