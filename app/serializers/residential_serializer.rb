# frozen_string_literal: true

# serializer for residential model
class ResidentialSerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :cost, :user_ids, :assigned_users, :lands_count, :total_expenses,
             :map_center, :map_bounds, :map_zoom_hint, :martin_lands_tile_url

  # Deprecated: first assigned user id (backward compatibility for older clients)
  attribute :user_id
  attribute :user_full_name

  def user_ids
    object.user_ids
  end

  def assigned_users
    object.users.map do |user|
      {
        id: user.id,
        name: user.name,
        last_name: user.last_name,
        email: user.email,
        role_name: user.role&.name
      }
    end
  end

  def user_id
    object.users.first&.id
  end

  def user_full_name
    user = object.users.first
    return nil unless user

    "#{user.name} #{user.last_name}"
  end

  def map_center
    object.map_center
  end

  def map_bounds
    object.map_bounds
  end

  def map_zoom_hint
    object.map_zoom_hint
  end

  def martin_lands_tile_url
    base = ENV.fetch("MARTIN_TILE_URL", "http://localhost:3030")
    "#{base}/lands/{z}/{x}/{y}?residential_id=#{object.id}"
  end

  def lands_count
    object.lands.count
  end

  def total_expenses
    return 0 if object.expenses.empty?

    object.expenses.sum(:amount)
  end

  def total_payments
    return 0 if object.payments.empty?

    object.payments.sum(:amount)
  end

  has_many :lands, if: -> { @instance_options[:include_lands] }
  has_many :expenses, if: -> { @instance_options[:include_expenses] }
  has_many :payments, if: -> { @instance_options[:include_payments] }
end
