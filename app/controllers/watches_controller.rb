class WatchesController < ApplicationController

  def index
    @watches = Watch.where(user: current_user) if current_user
  end

  def destroy
    @watch = Watch.find(params[:id])

    if @watch.destroy
      redirect_to watches_path, :notice => "You are no longer watching this data."
    else
      redirect_to watches_path, :notice => "Something went wrong, please contact a System Administrator."
    end
  end

  def update_last_seen_at
    if params[:view] == 'false'
      watched_obj = Watch.find_by(user: params[:current_user], source: params[:source])
    else
      watched_obj = Watch.find_by(user: params[:current_user], view: params[:view])
    end
    
    watched_obj.update_attribute('last_seen_at', Time.now) if watched_obj
    render json: {}
  end

  private

  def watch_params
    params.require(:watch).permit(:user_id, :source_id, :view_id, :last_seen_at, :last_triggered_at)
  end
end
