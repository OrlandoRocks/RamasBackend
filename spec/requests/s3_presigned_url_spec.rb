# frozen_string_literal: true

require 'rails_helper'
require 'aws-sdk-s3'

RSpec.describe "S3PresignedUrl" do
  let(:bucket_name) { "test-bucket" }
  let(:file_name) { "example.txt" }
  let(:expected_url) { "https://#{bucket_name}.s3.amazonaws.com/uploads/#{SecureRandom.uuid}/#{file_name}" }
  let(:aws_client_double) { instance_double(Aws::S3::Resource) }
  let(:bucket_double) { instance_double(Aws::S3::Bucket) }
  let(:object_double) { instance_double(Aws::S3::Object) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  before do
    allow(ENV).to receive(:fetch).with("S3_BUCKET_NAME", nil).and_return(bucket_name)
    allow(Aws::S3::Resource).to receive(:new).and_return(aws_client_double)
    allow(aws_client_double).to receive(:bucket).with(bucket_name).and_return(bucket_double)
    allow(bucket_double).to receive(:object).and_return(object_double)
    allow(object_double).to receive(:presigned_url).with(:put, expires_in: 3600).and_return(expected_url)
    allow(object_double).to receive(:public_url).and_return(expected_url)
  end

  describe "POST /s3_presigned_url" do
    it "returns a presigned URL and the public path" do
      post '/s3_presigned_url', params: { file_name: file_name }, headers: @headers

      expect(response).to have_http_status(:ok)
      expect(json['url']).to eq(expected_url)
      expect(json['path']).to eq(expected_url)
    end
  end

  def json
    JSON.parse(response.body)
  end

  def sign_in(user)
    post '/login', params: { auth: { email: user.email, password: 'password' } }
    @token = json['meta']['token']
    @headers = { 'Authorization': "Bearer #{@token}" }
  end
end
