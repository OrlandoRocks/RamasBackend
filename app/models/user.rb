# frozen_string_literal: true

# Description: User model that belongs to a role and has many expenses.
class User < ApplicationRecord
  belongs_to :role
  has_many :expenses, dependent: :nullify

  has_secure_password
  validates :email, presence: true, uniqueness: true


  def admin?
    role.name == "admin"
  end

  def client?
    role.name == "client"
  end

  def user?
    role.name == "user"
  end
end
