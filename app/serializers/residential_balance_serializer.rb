# frozen_string_literal: true

# serializer for residential model
class ResidentialBalanceSerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :cost, :user_ids, :assigned_users, :lands_count, :total_expenses, :total_payments,
             :payments_by_month, :expenses_by_month

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

  def payments_by_month
    return 0 if object.payments.empty?

    balance_params = @instance_options[:serializer_options]

    if balance_params[:start_date].nil?
      object.payments.where('extract(year from payments.created_at) = ?', balance_params[:year]).sum(:amount)
    else
      object.payments.where(created_at: @instance_options[:serializer_options][:start_date]..@instance_options[:serializer_options][:end_date]).sum(:amount)
    end
  end

  def expenses_by_month
    return 0 if object.expenses.empty?

    balance_params = @instance_options[:serializer_options]

    if balance_params[:start_date].nil?
      object.expenses.where('extract(year from expenses.created_at) = ?', balance_params[:year]).sum(:amount)
    else
      object.expenses.where(created_at: @instance_options[:serializer_options][:start_date]..@instance_options[:serializer_options][:end_date]).sum(:amount)
    end
  end

  has_many :lands, if: -> { @instance_options[:include_lands] }
  has_many :expenses, if: -> { @instance_options[:include_expenses] }
  has_many :payments, if: -> { @instance_options[:include_payments] }
end
