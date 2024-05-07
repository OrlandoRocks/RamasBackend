# frozen_string_literal: true

# serializer for user model
class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :last_name, :email
end
