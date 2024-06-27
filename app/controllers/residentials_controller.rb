# frozen_string_literal: true

# Handles the residentials of the application
class ResidentialsController < ApplicationController
  before_action :set_residential, only: %i[show update destroy]

  # GET /residentials
  # @return [void]
  def index
    @residentials = Residential.all
    authorize @residentials
    render json: @residentials
  end

  # GET /residentials/1
  # @return [void]
  def show
    render json: @residential, serializer: ResidentialSerializer,
           include_lands: true, include_expenses: true
  end

  # POST /residentials
  # @return [void]
  def create
    @residential = Residential.new(residential_params)

    if @residential.save
      render json: @residential, serializer: ResidentialSerializer, status: :created
    else
      render json: @residential.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /residentials/1
  # @return [void]
  def update
    if @residential.update(residential_params)
      params[:lands]&.each do |land_params|
        if land_params[:id].present?
          land = @residential.lands.find(land_params[:id])
          land.update(land_params.permit(:name, :size))
        else
          @residential.lands.create(land_params.permit(:type, :address, :block, :size, :price, :house_number))
        end
      end
      render json: @residential, serializer: ResidentialSerializer, include_lands: true, status: :ok
    else
      render json: @residential.errors, status: :unprocessable_entity
    end
  end

  # DELETE /residentials/1
  # @return [void]
  def destroy
    @residential.destroy
    render json: { message: "Residential was successfully destroyed." }, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # @return [void]
  def set_residential
    @residential = Residential.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  # @return [void]
  def residential_params
    params.require(:residential).permit(:name, :address, :cost, :user_id)
  end
end
