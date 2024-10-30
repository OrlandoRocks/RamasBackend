# frozen_string_literal: true

# Handles the balance of the application
class BalancesController < ApplicationController
  before_action :authorized

  def residentials_list
    @balance_residentials = Residential.all
    render json: @balance_residentials, adapter: :json_api, status: :ok
  end

  def get_balance_data
    if params[:residential_id].present?
      if params[:month].present?
        residential_ids = params[:residential_id].split(/,/).map(&:to_i)
        start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
        end_date = start_date.end_of_month
        
        #@records = Residential.with_payments_and_expenses_in_month(params[:year].to_i, params[:month].to_i)
        @records = Residential.where(id:[residential_ids])
  
        render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok, 
                                serializer_options: { start_date: start_date, end_date: end_date }
      else
        @records = Residential.find(params[:residential_id])
  
        render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok
      end
    else
      @records = Residential.all
  
      render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok
    end
  end

end
