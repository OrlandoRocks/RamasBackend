# frozen_string_literal: true

# serializer for user model
class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :last_name, :email, :role_id, :role_name, :full_name

  def full_name
    "#{object.name} #{object.last_name}"
  end

  def role_name
    "#{object.role.name}"
  end

  belongs_to :role
end
