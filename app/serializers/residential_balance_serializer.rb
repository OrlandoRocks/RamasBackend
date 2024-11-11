# frozen_string_literal: true

# serializer for residential model
class ResidentialBalanceSerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :cost, :user_id, :user_full_name, :lands_count, :total_expenses, :total_payments, :payments_by_month, :expenses_by_month

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

  def total_payments
    return 0 if object.payments.empty?

    object.payments.sum(:amount)
  end

  def payments_by_month
    return 0 if object.payments.empty?

    balance_params = @instance_options[:serializer_options]

    if balance_params[:start_date].nil?
      # Búsqueda anual
      object.payments.where('extract(year from payments.created_at) = ?', balance_params[:year]).sum(:amount)
    else
      # Búsqueda por mes
      object.payments.where(created_at: @instance_options[:serializer_options][:start_date]..@instance_options[:serializer_options][:end_date]).sum(:amount)
    end
  end

  def expenses_by_month
    return 0 if object.expenses.empty?

    balance_params = @instance_options[:serializer_options]

    if balance_params[:start_date].nil?
      # Búsqueda anual
      object.expenses.where('extract(year from expenses.created_at) = ?', balance_params[:year]).sum(:amount)
    else
      # Búsqueda por mes
      object.expenses.where(created_at: @instance_options[:serializer_options][:start_date]..@instance_options[:serializer_options][:end_date]).sum(:amount)
    end
  end

  has_many :lands, if: -> { @instance_options[:include_lands] }
  has_many :expenses, if: -> { @instance_options[:include_expenses] }
  has_many :payments, if: -> { @instance_options[:include_payments] }
end