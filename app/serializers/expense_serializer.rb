# frozen_string_literal: true

# serializer for expenses model
class ExpenseSerializer < ActiveModel::Serializer
  attributes :id, :account, :department, :type, :comments, :amount

  belongs_to :residential
  belongs_to :user
end
