class LandsController < ApplicationController
  before_action :set_land, only: %i[show update destroy]

  # GET /lands
  # @return [void]
  def index
    @lands = Land.all
    render json: @lands
  end

  # GET /lands/1
  # @return [void]
  def show
    render json: @land
  end

  # POST /lands
  # @return [void]
  def create
    @lands = Land.create(lands_params)
    if @lands.all?(&:persisted?)
      render json: @lands, status: :created
    else
      render json: @lands.map(&:errors), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /lands/1
  # @return [void]
  def update
    if @land.update(land_params)
      render json: @land
    else
      render json: @land.errors, status: :unprocessable_entity
    end
  end

  # DELETE /lands/1
  # @return [void]
  def destroy
    @land.destroy
    render json: { message: "Land was successfully destroyed." }, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # @return [void]
  def set_land
    @land = Land.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  # @return [void]
  def land_params
    params.require(:land).permit(:land_code, :address, :block, :size, :price, :house_number, :residential_id)
  end

  def lands_params
    params.require(:lands).map do |land|
      land.permit(:land_code, :address, :block, :size, :price, :house_number, :residential_id)
    end
  end
end

