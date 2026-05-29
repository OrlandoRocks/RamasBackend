# frozen_string_literal: true

class GeoLayersController < ApplicationController
  before_action :set_geo_layer, only: %i[show update destroy]

  # GET /geo_layers
  def index
    @geo_layers = policy_scope(GeoLayer)
    @geo_layers = @geo_layers.by_type(params[:layer_type]) if params[:layer_type]
    @geo_layers = @geo_layers.with_residential(params[:residential_id]) if params[:residential_id]

    authorize GeoLayer

    render json: @geo_layers
  end

  # GET /geo_layers/1
  def show
    authorize @geo_layer
    render json: @geo_layer
  end

  # GET /geo_layers/geojson
  def geojson
    @geo_layers = policy_scope(GeoLayer)
    @geo_layers = @geo_layers.by_type(params[:layer_type]) if params[:layer_type]
    @geo_layers = @geo_layers.with_residential(params[:residential_id]) if params[:residential_id]

    authorize GeoLayer, :geojson_collection?

    features = @geo_layers.map(&:as_geojson_feature)

    render json: {
      type: "FeatureCollection",
      features: features
    }
  end

  # POST /geo_layers
  def create
    @geo_layer = GeoLayer.new(geo_layer_params)
    authorize @geo_layer

    if @geo_layer.save
      render json: @geo_layer, status: :created
    else
      render json: @geo_layer.errors, status: :unprocessable_entity
    end
  end

  # POST /geo_layers/import_shapefile
  def import_shapefile
    unless params[:residential_id]
      return render json: { error: "residential_id is required" }, status: :unprocessable_entity
    end

    residential = policy_scope(Residential).find(params[:residential_id])
    authorize residential, :import_geo_layers?

    unless params[:file]
      return render json: { error: "No file provided" }, status: :unprocessable_entity
    end

    temp_dir = extract_shapefile(params[:file])
    shp_file = find_shp_file(temp_dir)

    unless shp_file
      cleanup_temp_dir(temp_dir)
      return render json: { error: "No .shp file found in upload" }, status: :unprocessable_entity
    end

    service = ShapefileImportService.new(shp_file)
    result = service.import_to_geo_layers(
      name: params[:name] || "Imported Layer",
      layer_type: params[:layer_type],
      residential_id: params[:residential_id]
    )

    cleanup_temp_dir(temp_dir)

    if result[:success]
      render json: {
        message: "Successfully imported #{result[:imported_count]} features",
        imported_count: result[:imported_count]
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

  # POST /geo_layers/preview_shapefile
  def preview_shapefile
    authorize GeoLayer, :preview_shapefile?

    unless params[:file]
      return render json: { error: "No file provided" }, status: :unprocessable_entity
    end

    temp_dir = extract_shapefile(params[:file])
    shp_file = find_shp_file(temp_dir)

    unless shp_file
      cleanup_temp_dir(temp_dir)
      return render json: { error: "No .shp file found in upload" }, status: :unprocessable_entity
    end

    service = ShapefileImportService.new(shp_file)
    preview = service.preview(limit: params[:limit]&.to_i || 10)

    cleanup_temp_dir(temp_dir)

    render json: preview
  rescue ShapefileImportService::ImportError => e
    cleanup_temp_dir(temp_dir) if temp_dir
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH/PUT /geo_layers/1
  def update
    authorize @geo_layer
    if @geo_layer.update(geo_layer_params)
      render json: @geo_layer
    else
      render json: @geo_layer.errors, status: :unprocessable_entity
    end
  end

  # DELETE /geo_layers/1
  def destroy
    authorize @geo_layer
    @geo_layer.destroy
    render json: { message: "GeoLayer was successfully destroyed." }, status: :ok
  end

  private

  def set_geo_layer
    @geo_layer = policy_scope(GeoLayer).find(params[:id])
  end

  def geo_layer_params
    params.require(:geo_layer).permit(:name, :layer_type, :description, :residential_id, :geometry, properties: {})
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
