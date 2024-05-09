# frozen_string_literal: true

require 'aws-sdk-s3'

RSpec.configure do |config|
  config.before(:each) do
    Aws.config[:s3] = {
      stub_responses: {
        get_object: { body: "data" },
        put_object: {}
      }
    }
  end
end
