class ShapefileExportsController < ApplicationController

  before_action :get_export

  def status
    render json: @export.try(:to_json)
  end

  def download
    if @export
      data = @export.tmp_shapefile.try(:fetch_data)
      @export.tmp_shapefile.try(:delete)
    end

    send_data data, filename: @export.try(:file_path)
  end

  protected

  def get_export
    @export = ShapefileExport.where(user: current_user, id: params[:id]).first
  end
end
