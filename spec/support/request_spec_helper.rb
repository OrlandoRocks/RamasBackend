# frozen_string_literal: true

# This helper is used to parse the JSON response from the API request
module RequestSpecHelper
  def json
    JSON.parse(response.body)
  end

  def auth_token_for_user(user)
    JwtService.encode({ user_id: user.id })
  end
end
