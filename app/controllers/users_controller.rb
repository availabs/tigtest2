class UsersController < ApplicationController
  before_filter :authenticate_user!
  add_breadcrumb 'All Users', :users_path
  respond_to :html, :json

  def index
    authorize! :index, User, :message => 'Not authorized as an administrator.'
    if current_user.has_role?(:agency_admin) && !current_user.has_role?(:admin)
      @users = User.where(agency_id: current_user.agency_id)
    else
      @users = User.all
    end
  end

  def new
    @user = User.new
    @agency = Agency.find(params[:agency]) if params[:agency]
  end

  def create
    @user = User.new(sign_up_params)
    @agency = params[:agency] ? Agency.find(params[:agency]) : params[:user][:agency_id] ? Agency.find(params[:user][:agency_id]) : nil

    @user.save
    yield @user if block_given?
    if @user.persisted?
      if current_user
        if current_user.has_any_role?(:admin, :agency_admin)
          roles = params[:user][:role_ids].reject(&:blank?).map(&:to_i)
          @user.add_role(:agency_user)
          roles.each {|r| @user.add_role(Role.find(r).name.to_sym) }
          redirect_to agency_path(Agency.find(params[:user][:agency_id])), :notice => "User created."
        end
      else
        if @user.active_for_authentication?
          set_flash_message :notice, :signed_up if is_flashing_format?
          sign_up(resource_name, @user)
          respond_with @user, location: after_sign_up_path_for(@user)
        else
          set_flash_message :notice, :"signed_up_but_#{@user.inactive_message}" if is_flashing_format?
          expire_data_after_sign_in!
          respond_with @user, location: after_inactive_sign_up_path_for(@user)
        end
        @user.add_role(:public).save
      end
    else
      respond_with @user, location: new_user_path(agency: @user.agency)
    end
  end

  def show
    authorize! :read, User, :message => "You are not permitted to view this user's data."
    @user = User.find(params[:id])
    add_breadcrumb "#{@user.display_name}", @user
  end

  def edit
    @user = User.find(params[:id])
    add_breadcrumb "Edit"
  end
  
  def update
    authorize! :update, User, :message => 'Not authorized as an administrator.'
    @user = User.find(params[:id])
    had_contributor_role_before = @user.has_role?(:contributor)
    had_librarian_role_before = @user.has_role?(:librarian)
    if @user.update_attributes(params[:user], :as => :admin)
      if !@user.has_any_role?(:agency_user, :agency_admin) && !@user.agency_id.nil?
        @user.update_attributes({agency_id: nil})
      end
      if !@user.has_role?(:contributor) && had_contributor_role_before
        Source.all.each do |source|
          if source.contributor_ids.include?(@user.id)
            corrected_contributor_ids = source.contributor_ids
            corrected_contributor_ids.delete(@user.id)
            source.update_attributes({contributor_ids: corrected_contributor_ids})
          end
        end
        View.all.each do |view|
          if view.contributor_ids.include?(@user.id)
            corrected_contributor_ids = view.contributor_ids
            corrected_contributor_ids.delete(@user.id)
            view.update_attributes({contributor_ids: corrected_contributor_ids})
          end
        end
      end
      if !@user.has_role?(:librarian) && had_librarian_role_before
        Source.all.each do |source|
          if source.librarian_ids.include?(@user.id)
            corrected_librarian_ids = source.librarian_ids
            corrected_librarian_ids.delete(@user.id)
            source.update_attributes({librarian_ids: corrected_librarian_ids})
          end
        end
        View.all.each do |view|
          if view.librarian_ids.include?(@user.id)
            corrected_librarian_ids = view.librarian_ids
            corrected_librarian_ids.delete(@user.id)
            view.update_attributes({librarian_ids: corrected_librarian_ids})
          end
        end
      end
      @user.add_role(:public) if @user.roles.empty?
      @user.add_role(:agency_user) if (@user.has_any_role?(:librarian, :contributor) && !@user.has_role?(:agency_user))
      redirect_to users_path, :notice => "User updated."
    else
      redirect_to users_path, :alert => "Unable to update user."
    end
  end
    
  def destroy
    authorize! :destroy, @user, :message => 'Not authorized as an administrator.'
    user = User.find(params[:id])
    unless user == current_user
      user.destroy
      redirect_to users_path, :notice => "User deleted."
    else
      redirect_to users_path, :notice => "Can't delete yourself."
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:display_name, :email, :phone, :password, :password_confirmation, :agency_id, :role_ids)
  end
end
