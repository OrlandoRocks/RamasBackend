# frozen_string_literal: true

# Handles the balance of the application
class BalancesController < ApplicationController
  def all_residentials
    authorize :balance, :all_residentials?

    @records = policy_scope(Residential)

    render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok,
           serializer_options: { year: DateTime.now.year }
  end

  def residentials_list
    authorize :balance, :residentials_list?

    @balance_residentials = policy_scope(Residential)

    render json: @balance_residentials, adapter: :json_api, status: :ok
  end

  def get_balance_data
    authorize :balance, :get_balance_data?

    base = policy_scope(Residential)

    if params[:residential_id].present?
      residential_ids = params[:residential_id].split(/,/).map(&:to_i)
      allowed_ids = base.pluck(:id)
      scoped_ids = residential_ids & allowed_ids

      @records = base.where(id: scoped_ids)

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
      @records = base

      render json: @records, each_serializer: ResidentialBalanceSerializer, adapter: :json_api, status: :ok,
             serializer_options: { year: DateTime.now.year }
    end
  end
end
