# frozen_string_literal: true

# Handles the balance of the application
class BalancesController < ApplicationController
  before_action :authorized

  def all_residentials
    @records = Residential.all
    render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok, 
                                serializer_options: { year: DateTime.now.year }
  end

  def residentials_list
    @balance_residentials = Residential.all
    render json: @balance_residentials, adapter: :json_api, status: :ok
  end

  def get_balance_data
    if params[:residential_id].present?
      residential_ids = params[:residential_id].split(/,/).map(&:to_i)
      @records = Residential.where(id:[residential_ids])

      if params[:month].present?
        start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
        end_date = start_date.end_of_month
        
        render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok, 
                                serializer_options: { start_date: start_date, end_date: end_date }
      else
        render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok,
                                serializer_options: { year: params[:year].to_i }
      end
    else
      @records = Residential.all
      render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok,
             serializer_options: { year: DateTime.now.year }
    end
  end

end
