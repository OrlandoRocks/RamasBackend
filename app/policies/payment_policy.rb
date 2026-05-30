# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if super_user?

      if staff? || seller?
        return scope.joins(contract: { land: { residential: :users } }).where(users: { id: user.id }).distinct
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
    client_owns_contract?(record.contract) ||
      ((manage_business_resources? || seller?) && assigned_to_residential?(record.contract&.land&.residential))
  end

  def create?
    (manage_business_resources? || seller?) && assigned_to_residential?(record.contract&.land&.residential)
  end

  def update?
    return false if client?

    (manage_business_resources? || seller?) &&
      assigned_to_residential?(record.contract&.land&.residential)
  end

  def destroy?
    manage_business_resources? && assigned_to_residential?(record.contract&.land&.residential)
  end

  def payment_statuses?
    authenticated?
  end

  private

  def client_owns_contract?(contract)
    client? && user.client_id.present? && contract&.client_id == user.client_id
  end
end
