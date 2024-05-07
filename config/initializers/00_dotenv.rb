
Rails.application.credentials.tap do |d|
  d.secret_key_base = ENV['SECRET_KEY_BASE']
end


