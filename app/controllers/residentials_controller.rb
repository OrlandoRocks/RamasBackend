# frozen_string_literal: true

# controller for residentials model
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
      render json: @residential, serializer: ResidentialSerializer, status: :ok
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
