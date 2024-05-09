# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResidentialPolicy do
  let(:admin) { User.new(role: 'admin') }
  let(:user) { User.new(role: 'user') }
  let(:another_user) { User.new(role: 'user') }
  let(:residential) { Residential.new(user: user) }

  subject { described_class }

  describe 'Scope' do
    let(:scope) { Residential.all }

    it 'resuelve todos los registros' do
      expect(subject::Scope.new(admin, scope).resolve).to eq(scope)
    end
  end

  permissions :show?, :index? do
    it 'permite a cualquier usuario ver una residencia' do
      expect(subject).to permit(admin, residential)
      expect(subject).to permit(user, residential)
      expect(subject).to permit(another_user, residential)
    end
  end

  permissions :create?, :update?, :destroy? do
    it 'permite a un administrador crear, actualizar o eliminar una residencia' do
      expect(subject).to permit(admin, residential)
    end

    it 'permite al usuario propietario crear, actualizar o eliminar su propia residencia' do
      expect(subject).to permit(user, residential)
    end

    it 'no permite a un usuario diferente crear, actualizar o eliminar una residencia ajena' do
      expect(subject).not_to permit(another_user, residential)
    end
  end
end
