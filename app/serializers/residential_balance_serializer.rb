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
   # return 0 if object.contracts.payments.empty?

    #object.payments.sum(:amount)
  end

  def payments_by_month
    return 0 if object.contracts.empty?

    payments_paid = object.contracts.each_with_object([]) do |contract, sum_payments|
      sum_payments << contract.payments.where(status: Payment.payment_statuses['Pagado'], 
                              created_at: @instance_options[:serializer_options][:start_date]..@instance_options[:serializer_options][:end_date]).sum(:amount)
    end

    payments_paid.sum
    #object.payments.where(created_at: @instance_options[:serializer_options][:start_date]..@instance_options[:serializer_options][:end_date]).sum(:amount)
  end

  def expenses_by_month
    return 0 if object.expenses.empty?

    object.expenses.where(created_at: @instance_options[:serializer_options][:start_date]..@instance_options[:serializer_options][:end_date]).sum(:amount)
  end

  has_many :lands, if: -> { @instance_options[:include_lands] }
  has_many :expenses, if: -> { @instance_options[:include_expenses] }
  has_many :payments, if: -> { @instance_options[:include_payments] }
end
