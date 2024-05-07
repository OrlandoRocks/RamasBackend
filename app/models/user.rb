class User < ApplicationRecord
  belongs_to :role
  has_many :expenses

  has_secure_password

  def admin?
    role.name == 'admin'
  end

  def client?
    role.name == 'client'
  end

  def user?
    role.name == 'user'
  end
end
