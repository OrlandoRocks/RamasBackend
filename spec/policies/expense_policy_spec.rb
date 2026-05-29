# frozen_string_literal: true

require 'rails_helper'
require 'pundit/rspec'

RSpec.describe ExpensePolicy, type: :policy do
  let(:seller_role) { Role.find_or_create_by!(name: 'user') }
  let(:admin_role) { Role.find_or_create_by!(name: 'admin') }
  let(:client_role) { Role.find_or_create_by!(name: 'client') }

  let(:seller) { create(:user, role: seller_role) }
  let(:admin) { create(:user, role: admin_role) }
  let(:client_user) { create(:user, role: client_role) }

  let(:seller_residential) { create(:residential, user: seller) }
  let(:expense) { create(:expense, residential: seller_residential, user: seller) }

  permissions :index? do
    it 'denies client' do
      expect(described_class).not_to permit(client_user, Expense)
    end

    it 'permits seller' do
      expect(described_class).to permit(seller, Expense)
    end
  end

  permissions :create? do
    it 'permits seller only for their residential and their user_id' do
      new_expense = build(:expense, residential: seller_residential, user: seller)
      expect(described_class).to permit(seller, new_expense)
    end

    it 'denies seller when user_id does not match' do
      other = create(:user, role: seller_role)
      new_expense = build(:expense, residential: seller_residential, user: other)
      expect(described_class).not_to permit(seller, new_expense)
    end
  end

  permissions :update? do
    it 'permits admin' do
      expect(described_class).to permit(admin, expense)
    end

    it 'denies seller' do
      expect(described_class).not_to permit(seller, expense)
    end
  end

  describe ExpensePolicy::Scope do
    it 'scopes seller to expenses in their residentials' do
      other_residential = create(:residential)
      other_expense = create(:expense, residential: other_residential, user: other_residential.user)

      resolved = described_class.new(seller, Expense.all).resolve
      expect(resolved).to include(expense)
      expect(resolved).not_to include(other_expense)
    end
  end
end
