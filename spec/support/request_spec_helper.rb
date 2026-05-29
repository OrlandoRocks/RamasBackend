# frozen_string_literal: true

# This helper is used to parse the JSON response from the API request
module RequestSpecHelper
  def sign_in(user)
    account = User.find(user.id)

    post "/login", params: { auth: { email: account.email, password: "password" } }
    expect(response).to have_http_status(:accepted), -> { response.body }

    @token = json.dig("meta", "token")
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  def json
    JSON.parse(response.body)
  end
end
