class RegistrationsController < Devise::RegistrationsController
  skip_before_action :require_no_authentication, only: [:new, :create]
 
  def create
    build_resource(sign_up_params)
    
    resource.save
    yield resource if block_given?
    if resource.persisted?
      if current_user
        if current_user.has_any_role?(:admin, :agency_admin)
          roles = params[:user][:role_ids].reject(&:blank?).map(&:to_i)
          resource.add_role(:agency_user)
          roles.each {|r| resource.add_role(Role.find(r).name.to_sym) }
          redirect_to agency_path(Agency.find(params[:user][:agency_id])), :notice => "User created."
        end
      else
        if resource.active_for_authentication?
          set_flash_message :notice, :signed_up if is_flashing_format?
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
        resource.add_role(:public).save
      end
    else
      respond_with resource
    end
  end

  def edit
    @user = User.find(params[:format])
    authorize! :edit, @user, :message => 'Not authorized as an administrator.'
  end

  def update
    @user = User.find(params[:user][:edited_user])
    params[:user].delete :edited_user
    respond_to do |format|
      if current_user.has_role?(:admin) && current_user != @user || (current_user.has_role?(:agency_admin) && (current_user.agency == @user.agency) && !@user.has_any_role?(:agency_admin, :admin)) && current_user != @user
        [:password, :password_confirmation, :current_password].each { |p| params[:user].delete(p) if params[:user][p].blank? }
        if @user.update(params[:user])
          format.html { redirect_to @user, notice: 'User was successfully updated.' }
        else
          format.html { render action: 'edit', notice: "There was an error updating the user." }
        end
      else
        super
        format.html { }
      end
    end
  end

  private
 
  def sign_up_params
    params.require(:user).permit(:display_name, :email, :phone, :password, :password_confirmation, :agency_id)
  end
 
  def account_update_params
    params.require(:user).permit(:display_name, :email, :phone, :recent_activity_dashboard_limit, :recent_activity_expanded_limit, :snapshot_limit, :password, :password_confirmation, :current_password, :agency_id)
  end
end
