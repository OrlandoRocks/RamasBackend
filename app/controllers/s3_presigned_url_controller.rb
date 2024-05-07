# frozen_string_literal: true

# controller for generating presigned URLs for S3 uploads
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Object.html#presigned_url-instance_method
class S3PresignedUrlController < ApplicationController

  def create
    s3_client = Aws::S3::Resource.new
    obj = s3_client.bucket(ENV['S3_BUCKET_NAME']).object("uploads/#{SecureRandom.uuid}/#{params[:file_name]}")
    presigned_url = obj.presigned_url(:put, expires_in: 3600)

    render json: { url: presigned_url, path: obj.public_url }
  end

end
