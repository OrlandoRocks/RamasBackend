# frozen_string_literal: true

# serializer for client model
class ClientSerializer < ActiveModel::Serializer
  attributes :id, :code, :full_name, :identification_card, :rfc, :address, :colony,
             :zip_code, :phone_number, :city, :state, :country, :assignee, :email, :birthday,
             :nationality, :civil_status, :spouse, :economic_dependants, :home_owner, :occupation,
             :company, :company_address, :company_phone, :monthly_income, :monthly_expenses, :comments, :image
end
