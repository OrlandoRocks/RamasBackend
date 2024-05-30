# frozen_string_literal: true

# serializer for expenses model
class ExpenseSerializer < ActiveModel::Serializer
  attributes :id, :account, :department, :expense_type, :comments, :amount, :user_id, :user_full_name, :residential_id,
             :residential_name

  def user_full_name
    "#{object.user.name} #{object.user.last_name}"
  end

  def residential_name
    "#{object.residential.name}"
  end

  belongs_to :residential
  belongs_to :user
end
