class StudyAreasController < ApplicationController
  before_action :set_study_area, only: [:edit, :update, :destroy]

  def index
    authorize! :index, StudyArea
    
    @admin = params[:admin] if params[:admin]
    @study_areas = @admin ? StudyArea.all : StudyArea.where("user_id = ? OR published = ?", current_user.id, true)
    add_breadcrumb 'My Study Areas'
  end

  def new
    @study_area = StudyArea.new
  end

  def create
    geom = BaseGeometry.new(geom: BaseGeometry.geom_from_wkt(params[:study_area][:wkt]))
    @study_area = StudyArea.new(study_area_params.merge(base_geometry: geom, type: :study_area))

    respond_to do |format|
      if @study_area.save
        format.json { render json: @study_area }
      else
        format.html { redirect_to :back }
        format.json { render json: @study_area.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    add_breadcrumb "Edit Study Area"
    @available_viewers = User.all.reject{|u| @study_area.viewers.include?(u) || u == current_user }.map{ |c| [(c.display_name.nil? ? c.email : c.display_name), c.id] }
    @existing_viewers = @study_area.viewers.map{ |c| [(c.display_name.nil? ? c.email : c.display_name), c.id] }
    @viewers = @available_viewers + @existing_viewers
  end

  def update
    respond_to do |format|
      if @study_area.update(study_area_params)
        format.html do
          current_user.has_role?(:admin) ? redirect_to(study_areas_path(admin: true)) : redirect_to(study_areas_path)
          flash[:notice] = "Study Area updated."
        end
      else
        format.html { render action: "edit", alert: "There was a problem updating this Study Area." }
        format.json { render json: @study_area.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @study_area.destroy
      redirect_to study_areas_path
      flash[:notice] = "Study area deleted."
    end
  end

  private

    def set_study_area
      @study_area = StudyArea.find(params[:id])
    end

    def study_area_params
      params.require(:study_area).permit(:user_id, :name, :description, :published, {:viewer_ids => []})
    end
end
