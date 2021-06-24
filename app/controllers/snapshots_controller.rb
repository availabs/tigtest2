class SnapshotsController < ApplicationController
  before_action :set_snapshot, only: [:show, :edit, :update, :destroy]
  before_filter :enforce_ownership, only: [:edit, :destroy]

  def show
    @snapshot = Snapshot.find(params[:id])
    options = {
      :controller => (@snapshot.app == "chart" ? "view_charts" : "views"),
      :action => @snapshot.app,
      :id => @snapshot.view_id,
      :area_id => (@snapshot.area_id ||= -1),
      :lower => (@snapshot.range_low ||= ''),
      :upper => (@snapshot.range_high ||= ''),
      :snapshot => (@snapshot.id ||= '')
    }

    if @snapshot.filters
      @snapshot.filters.each do |k,v|
        if k.to_s.match(/\w+\d/)
          session[k] = v if !v.nil?
        else
          options[k] = v
        end
      end
    end
    
    redirect_to options
  end

  def new
    @snapshot = Snapshot.new
  end

  def edit
    add_breadcrumb "Edit Snapshot"
    @available_viewers = User.all.reject{|u| @snapshot.viewers.include?(u) || u == current_user }.map{ |c| [(c.display_name.nil? ? c.email : c.display_name), c.id] }
    @existing_viewers = @snapshot.viewers.map{ |c| [(c.display_name.nil? ? c.email : c.display_name), c.id] }
    @viewers = @available_viewers + @existing_viewers
  end

  def create
    @snapshot = Snapshot.new(snapshot_params)
    @snapshot.user = current_user
    @snapshot.app = Snapshot.apps[@snapshot.app]
    @snapshot.range_high = (@snapshot.range_high == 0 ? nil : @snapshot.range_high)
    @snapshot.range_low = (@snapshot.range_low == 0 ? nil : @snapshot.range_low)
    unless @snapshot.filters.blank? || @snapshot.filters.empty? || @snapshot.filters.nil?
      @snapshot.filters = eval(@snapshot.filters)
      @snapshot.filters.delete(:area_id) if @snapshot.filters[:area_id]
    end
    unless params[:snapshot][:viewer_ids].blank?
      viewer_ids = params[:snapshot][:viewer_ids].reject(&:blank?).map(&:to_i)
      @snapshot.viewer_ids = viewer_ids
    end

    respond_to do |format|
      if @snapshot.save
        if @snapshot.app
          format.json { render json: @snapshot }
        else
          redirect_to snapshots_path
        end
      else
        format.html { render action: "new" }
        format.json { render json: @snapshot.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    snap = params[:snapshot]
    edit_page = snap[:viewer_ids]

    if !edit_page
      snap[:range_high] = (snap[:range_high] == 0 ? nil : snap[:range_high])
      snap[:range_low] = (snap[:range_low] == 0 ? nil : snap[:range_low])
    end
    unless snap[:filters].blank? || snap[:filters].empty? || snap[:filters].nil?
      snap[:filters] = eval(snap[:filters])
      snap[:filters].delete(:area_id) if snap[:filters][:area_id]
    end

    respond_to do |format|
      if @snapshot.update(snap)
        @snapshot.viewer_ids = snap[:viewer_ids].reject(&:blank?).map(&:to_i) if edit_page
        format.json { render json: @snapshot } if @snapshot.app
        format.html do
          redirect_to :controller => 'home', :action => 'index', :expand => "snap"
          flash[:notice] = "Snapshot updated."
        end
      else
        format.html { render action: "edit", alert: "There was a problem saving your snapshot." }
        format.json { render json: @snapshot.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @snapshot.destroy
      redirect_to :controller=> 'home', :action => 'index', :expand => "snap"
      flash[:notice] = "Snapshot destroyed."
    end
  end

  private
    def enforce_ownership
      @snapshot = Snapshot.find(params[:id])
      if user_signed_in?
        redirect_to (request.env["HTTP_REFERER"] || '/?expand=snap'), alert: "You are not permitted to edit this snapshot." if @snapshot.user != current_user
      else
        redirect_to (request.env["HTTP_REFERER"] || root_path), alert: "You are not permitted to edit this snapshot."
      end
    end

    def set_snapshot
      @snapshot = Snapshot.find(params[:id])
    end

    def snapshot_params
      params.require(:snapshot).permit(:user_id, :name, :description, :view_id, :app, :area_id, :range_low, :range_high, :filters, :table_settings, :map_settings, :published, :viewer_ids)
    end
end
