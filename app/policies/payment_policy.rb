# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if staff?

      if seller?
        return scope.joins(contract: { land: :residential }).where(residentials: { user_id: user.id })
      end

      if client? && user.client_id.present?
        return scope.joins(:contract).where(contracts: { client_id: user.client_id })
      end

      scope.none
    end
  end

  def index?
    authenticated?
  end

  def show?
    manage_business_resources? ||
      (seller? && seller_owns_contract?(record.contract)) ||
      client_owns_contract?(record.contract)
  end

  def create?
    manage_business_resources? ||
      (seller? && seller_owns_contract?(record.contract))
  end

  def update?
    manage_business_resources?
  end

  def destroy?
    manage_business_resources?
  end

  def payment_statuses?
    authenticated?
  end

  private

  def seller_owns_contract?(contract)
    contract&.land&.residential&.user_id == user.id
  end

  def client_owns_contract?(contract)
    client? && user.client_id.present? && contract&.client_id == user.client_id
  end
end
