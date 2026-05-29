# frozen_string_literal: true

# Serializer for user model (signup, profile, and super-user management).
class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :last_name, :email, :role_id, :client_id, :role_name, :created_at, :updated_at

  def role_name
    object.role&.name
  end
end
