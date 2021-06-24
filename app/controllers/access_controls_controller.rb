class AccessControlsController < ApplicationController

  def new
    authorize! :create, AccessControl
    add_breadcrumb "New Access Controls"
    @access_control = AccessControl.new
  end

  def edit
    authorize! :update, AccessControl
    add_breadcrumb "Edit Access Controls"
    @access_control = AccessControl.find(params[:id])
  end

  def create
    parsed = params[:access_control].map{|k,v| v}
    parsed.each do |ac|
      ac[:role] = ac[:role].blank? ? nil : ac[:role]
      ac[:user_id] = ac[:user_id].blank? ? nil : ac[:user_id]
      AccessControl.create(ac)
    end

    redirect_to sources_path
    flash[:notice] = "Access controls were successfully created."
  end

  def update
    parsed = params[:access_control].map{|k,v| v}
    parsed.each do |ac|
      ac[:role] = ac[:role].blank? ? nil : ac[:role]
      ac[:user_id] = ac[:user_id].blank? ? nil : ac[:user_id]
      to_update = AccessControl.where(role: ac[:role],
                                      source_id: ac[:source_id],
                                      view_id: ac[:view_id],
                                      agency_id: ac[:agency_id],
                                      user_id: ac[:user_id]).first_or_create
      AccessControl.update(to_update.id, ac)
    end

    redirect_to sources_path
    flash[:notice] = "Access controls updated."
  end

  def destroy
    if @access_control.destroy
      redirect_to :back
      flash[:notice] = "Access controls destroyed."
    end
  end

  def restore_default
    view = params[:view]
    source = params[:source]
    query_obj = view ? view : source
    query_str = view ? 'view_id' : 'source_id'

    specific_agency_controls = AccessControl.where("#{query_str} = ? and role = ? and agency_id IS NOT NULL", query_obj, "agency")
    specific_user_controls = AccessControl.where("#{query_str} = ? and role = ? and agency_id IS NULL and user_id IS NOT NULL", query_obj, "agency")
    agency_user_controls = AccessControl.find_by("#{query_str} = ? and role = ? and agency_id IS NULL and user_id IS NULL", query_obj, "agency")
    public_user_controls = AccessControl.find_by("#{query_str} = ? and role = ? and agency_id IS NULL and user_id IS NULL", query_obj, "public")
    guest_user_controls = AccessControl.find_by("#{query_str} = ? and role IS NULL and agency_id IS NULL and user_id IS NULL", query_obj)

    specific_agency_controls.destroy_all
    specific_user_controls.destroy_all
    agency_user_controls ? agency_user_controls.update_attributes(show: true, download: true, comment: true) : AccessControl.where(view_id: view, role: "agency", show: true, download: true, comment: true).first_or_create
    public_user_controls ? public_user_controls.update_attributes(show: true, download: false, comment: false) : AccessControl.where(view_id: view, role: "public", show: true, download: false, comment: false).first_or_create
    guest_user_controls ? guest_user_controls.update_attributes(show: false, download: false, comment: false) : AccessControl.where(view_id: view, show: false, download: false, comment: false).first_or_create

    redirect_to (view ? view_path(view) : source_path(source)), notice: "Access Controls have been reset."
  end

  def use_source
    view = View.find(params[:view])

    if AccessControl.exist_for_object?(view.source)
      AccessControl.where(view_id: view.id).destroy_all
      source_access_controls = AccessControl.where(source_id: view.source.id)
      source_access_controls.each do |access_control|
        clone = access_control.dup
        clone.source_id = nil
        clone.view_id = view.id
        clone.save
      end
      redirect_to view_path(view), notice: "Access Controls have been set to match the Source."
    else
      redirect_to view_path(view), notice: "No Access Controls are set for the Source."
    end
  end

  private

    def access_control_params
      params.require(:access_control).permit(:source_id, :view_id, :agency_id, :user_id, :role, :show, :download, :comment)
    end
end
