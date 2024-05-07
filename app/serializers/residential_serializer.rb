# frozen_string_literal: true

# serializer for residential model
class ResidentialSerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :cost, :user_id, :user_full_name, :lands_count, :total_expenses

  def user_full_name
    "#{object.user.name} #{object.user.last_name}"
  end

  def lands_count
    object.lands.count
  end

  def total_expenses
    return 0 if object.expenses.empty?

    object.expenses.sum(:amount)
  end

  has_many :lands, if: -> { @instance_options[:include_lands] }
  has_many :expenses, if: -> { @instance_options[:include_expenses] }
end

