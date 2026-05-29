# frozen_string_literal: true

class ContractPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      return scope.all if super_user?

      if staff? || seller?
        return scope.joins(land: { residential: :users }).where(users: { id: user.id }).distinct
      end

      return scope.where(client_id: user.client_id) if client? && user.client_id.present?

      scope.none
    end
  end

  def index?
    authenticated?
  end

  def show?
    client_own_contract?(record) ||
      ((manage_business_resources? || seller?) && assigned_to_residential?(record.land&.residential))
  end

  def create?
    (manage_business_resources? || seller?) && sellers_land?(land_for(record))
  end

  def update?
    manage_business_resources? && assigned_to_residential?(record.land&.residential)
  end

  def destroy?
    manage_business_resources? && assigned_to_residential?(record.land&.residential)
  end

  def payments?
    show?
  end

  private

  def land_for(contract)
    return unless contract.respond_to?(:land_id)

    Land.find_by(id: contract.land_id)
  end

  def sellers_land?(land)
    assigned_to_residential?(land&.residential)
  end

  def client_own_contract?(contract)
    client? && user.client_id.present? && contract.client_id == user.client_id
  end

  def preview_template?
    @user.admin? || @user.user? || @user.client?
  end

  def generate_custom_pdf?
    @user.admin? || @user.user? || @user.client?
  end

  def save_version?
    @user.admin? || @user.user?
  end
end
