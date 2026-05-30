# frozen_string_literal: true

# Description: User model that belongs to a role and has many expenses.
class User < ApplicationRecord
  belongs_to :role
  belongs_to :client, optional: true
  has_many :expenses, dependent: :nullify

  has_many :residential_assignments, dependent: :destroy
  has_many :residentials, through: :residential_assignments

  has_secure_password
  validates :email, presence: true, uniqueness: true

  validate :client_profile_consistency

  def super_user?
    role&.name == "super_user"
  end

  def admin?
    role&.name == "admin"
  end

  # Product role name in DB is "user" — treated as seller / vendedor
  def seller?
    role&.name == "user"
  end

  def client?
    role&.name == "client"
  end

  def staff?
    super_user? || admin?
  end

  def can_assign_user_roles?
    super_user?
  end

  private

  def client_profile_consistency
    return if client_id.blank?

    unless client?
      errors.add(:client_id, "can only be set for users with the client role")
    end
  end
end
