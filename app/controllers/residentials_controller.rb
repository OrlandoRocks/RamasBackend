# frozen_string_literal: true

# Handles the residentials of the application
class ResidentialsController < ApplicationController
  before_action :set_residential, only: %i[show update destroy geojson lands_geojson]

  # GET /residentials
  def index
    @residentials = policy_scope(Residential)
    authorize Residential

    render json: @residentials
  end

  # GET /residentials/1
  def show
    authorize @residential
    render json: @residential, serializer: ResidentialSerializer,
           include_lands: true, include_expenses: true
  end

  # GET /residentials/1/geojson
  def geojson
    authorize @residential, :geojson?

    feature = @residential.as_geojson_feature
    if feature
      render json: {
        type: "FeatureCollection",
        features: [feature]
      }
    else
      render json: { error: "No boundary geometry defined" }, status: :not_found
    end
  end

  # GET /residentials/1/lands_geojson
  def lands_geojson
    authorize @residential, :lands_geojson?

    render json: @residential.lands_as_geojson
  end

  # POST /residentials
  def create
    @residential = Residential.new(residential_attributes)
    authorize @residential

    if save_residential_with_assignments(@residential)
      render json: @residential, serializer: ResidentialSerializer, status: :created
    else
      render json: @residential.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /residentials/1
  def update
    authorize @residential

    @residential.assign_attributes(residential_attributes)
    if save_residential_with_assignments(@residential)
      params[:lands]&.each do |land_params|
        if land_params[:id].present?
          land = @residential.lands.find(land_params[:id])
          land.update(land_params.permit(:name, :size, :geometry))
        else
          @residential.lands.create(land_params.permit(:type, :address, :block, :size, :price, :house_number, :geometry))
        end
      end
      render json: @residential, serializer: ResidentialSerializer, include_lands: true, status: :ok
    else
      render json: @residential.errors, status: :unprocessable_entity
    end
  end

  # DELETE /residentials/1
  def destroy
    authorize @residential
    @residential.destroy
    render json: { message: "Residential was successfully destroyed." }, status: :ok
  end

  private

  def set_residential
    @residential = policy_scope(Residential).find(params[:id])
  end

  def residential_attributes
    residential_params.except(:user_ids)
  end

  def residential_params
    params.require(:residential).permit(:name, :address, :cost, :boundary, user_ids: [])
  end

  def assignment_user_ids
    ids = params.dig(:residential, :user_ids)
    return nil if ids.nil?

    ids.reject(&:blank?).map(&:to_i)
  end

  def save_residential_with_assignments(residential)
    Residential.transaction do
      residential.save!
      sync_assignments!(residential)
      true
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  def sync_assignments!(residential)
    ids = assignment_user_ids
    return if ids.nil?

    assignable = User.where(id: ids).joins(:role).where(roles: { name: %w[user admin super_user] })
    residential.users = assignable
  end
end
