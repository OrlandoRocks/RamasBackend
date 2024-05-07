require 'rails_helper'

RSpec.describe 'Users::RegistrationsController', type: :request do
  let(:user_params) do
    { user: { email: 'test@example.com', password: 'password', password_confirmation: 'password' } }
  end

  describe 'POST /users' do
    context 'when registration is successful' do
      it 'returns a success message and the user data' do
        post user_registration_path, params: user_params
        expect(response).to have_http_status(:ok)
        expect(json['message']).to eq('Se armo el guiso ya te logueaste :D')
        expect(json['user']['email']).to eq('test@example.com')
      end
    end

    context 'when registration fails' do
      before { allow_any_instance_of(User).to receive(:persisted?).and_return(false) }

      it 'returns a failure message' do
        post user_registration_path, params: user_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['message']).to eq('Algo valio shit :(')
      end
    end
  end
end
