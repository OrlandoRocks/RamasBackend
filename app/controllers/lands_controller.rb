# frozen_string_literal: true

class LandsController < ApplicationController
  before_action :set_land, only: %i[show update destroy]

  # GET /lands
  def index
    @lands = policy_scope(Land).includes(:residential, :contract, :client)
    @lands = @lands.where(residential_id: params[:residential_id]) if params[:residential_id]

    if params[:format] == "geojson"
      authorize Land, :geojson_collection?

      features = @lands.where.not(geometry: nil).map(&:as_geojson_feature).compact
      render json: { type: "FeatureCollection", features: features }
    else
      authorize Land
      render json: @lands
    end
  end

  # GET /lands/1
  def show
    authorize @land
    render json: @land
  end

  # POST /lands
  def create
    attrs_list = lands_params
    attrs_list.each { |attrs| authorize Land.new(attrs) }
    @lands = Land.create(attrs_list)
    if @lands.all?(&:persisted?)
      render json: @lands, status: :created
    else
      render json: @lands.map(&:errors), status: :unprocessable_entity
    end
  end

  # POST /lands/import_shapefile
  def import_shapefile
    unless params[:residential_id]
      return render json: { error: "residential_id is required" }, status: :unprocessable_entity
    end

    residential = policy_scope(Residential).find(params[:residential_id])
    authorize residential, :import_lands?

    unless params[:file]
      return render json: { error: "No file provided" }, status: :unprocessable_entity
    end

    temp_dir = extract_shapefile(params[:file])
    shp_file = find_shp_file(temp_dir)

    unless shp_file
      cleanup_temp_dir(temp_dir)
      return render json: { error: "No .shp file found in upload" }, status: :unprocessable_entity
    end

    mapping = params[:mapping]&.to_unsafe_h || default_land_mapping
    service = ShapefileImportService.new(shp_file)
    result = service.import_to_lands(
      residential_id: params[:residential_id],
      mapping: mapping
    )

    cleanup_temp_dir(temp_dir)

    if result[:success]
      render json: {
        message: "Successfully imported #{result[:imported_count]} lands",
        imported_count: result[:imported_count],
        lands: result[:lands]
      }, status: :created
    else
      render json: {
        message: "Import completed with errors",
        imported_count: result[:imported_count],
        errors: result[:errors]
      }, status: :multi_status
    end
  rescue ShapefileImportService::ImportError => e
    cleanup_temp_dir(temp_dir) if temp_dir
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH/PUT /lands/1
  def update
    authorize @land
    if @land.update(land_params)
      render json: @land
    else
      render json: @land.errors, status: :unprocessable_entity
    end
  end

  # DELETE /lands/1
  def destroy
    authorize @land
    @land.destroy
    render json: { message: "Land was successfully destroyed." }, status: :ok
  end

  private

  def set_land
    @land = policy_scope(Land).includes(:residential, :contract, :client).find(params[:id])
  end

  def land_params
    params.require(:land).permit(:land_code, :address, :block, :size, :price, :house_number, :residential_id, :geometry)
  end

  def lands_params
    params.require(:lands).map do |land|
      land.permit(:land_code, :address, :block, :size, :price, :house_number, :residential_id, :geometry)
    end
  end

  def default_land_mapping
    {
      land_code: "land_code",
      address: "address",
      block: "block",
      size: "size",
      price: "price",
      house_number: "house_num"
    }
  end

  def extract_shapefile(uploaded_file)
    temp_dir = Rails.root.join("tmp", "shapefiles", SecureRandom.uuid)
    FileUtils.mkdir_p(temp_dir)

    if uploaded_file.content_type == "application/zip" || uploaded_file.original_filename.end_with?(".zip")
      extract_zip(uploaded_file, temp_dir)
    else
      FileUtils.cp(uploaded_file.tempfile.path, temp_dir.join(uploaded_file.original_filename))
    end

    temp_dir.to_s
  end

  def extract_zip(zip_file, dest_dir)
    require "zip"

    Zip::File.open(zip_file.tempfile.path) do |zip|
      zip.each do |entry|
        next if entry.directory?

        entry_name = File.basename(entry.name)
        entry_path = File.join(dest_dir.to_s, entry_name)

        File.open(entry_path, "wb") do |f|
          f.write(entry.get_input_stream.read)
        end
      end
    end
  end

  def find_shp_file(directory)
    Dir.glob(File.join(directory, "**", "*.shp")).first
  end

  def cleanup_temp_dir(temp_dir)
    FileUtils.rm_rf(temp_dir) if temp_dir && File.directory?(temp_dir)
  end
end
