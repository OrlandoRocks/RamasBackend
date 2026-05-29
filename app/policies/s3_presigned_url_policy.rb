# frozen_string_literal: true

class S3PresignedUrlPolicy < ApplicationPolicy
  def create?
    authenticated?
  end
end
