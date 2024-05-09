# frozen_string_literal: true

# This helper is used to parse the JSON response from the API request
module RequestSpecHelper
  def sign_in(user)
    post '/login', params: { auth: { email: user.email, password: 'password' } }
    @token = json['meta']['token']
    @headers = { 'Authorization': "Bearer #{@token}" }
  end

  def json
    JSON.parse(response.body)
  end
end
