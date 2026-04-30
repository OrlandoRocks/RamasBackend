# frozen_string_literal: true

# Policy for contract
class ContractPolicy < ApplicationPolicy
  # Scope class for contract
  class Scope < Scope
    def resolve
      if @user.admin?
        scope.all
      else
        scope.where(client_id: @user.id)
      end
    end
  end

  def show?
    @user.admin? || @user.user? || @user.client?
  end

  def index?
    @user.admin? || @user.user? || @user.client?
  end

  def create?
    @user.user?
  end

  def update?
    @user.admin?
  end

  def destroy?
    @user.admin?
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
